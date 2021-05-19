// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2021 SUSE LLC

use std::convert::TryInto;
use std::env;
use std::ffi::OsStr;
use std::fs;
use std::io;
use std::io::prelude::*;
use std::os::unix::ffi::OsStrExt;
use std::os::unix::fs::FileTypeExt;
use std::os::unix::fs::MetadataExt as UnixMetadataExt;
use std::path::{Path, PathBuf};

use crosvm::argument::{self, Argument};

macro_rules! NEWC_HDR_FMT {
    () => {
        concat!(
            "{magic}{ino:08X}{mode:08X}{uid:08X}{gid:08X}{nlink:08X}",
            "{mtime:08X}{filesize:08X}{major:08X}{minor:08X}{rmajor:08X}",
            "{rminor:08X}{namesize:08X}{chksum:08X}"
        )
    };
}

// Don't print debug messages on release builds...
#[cfg(debug_assertions)]
macro_rules! dout {
    ($($l:tt)*) => { println!($($l)*); }
}
#[cfg(not(debug_assertions))]
macro_rules! dout {
    ($($l:tt)*) => {};
}

const NEWC_HDR_LEN: u64 = 110;
const PATH_MAX: u64 = 4096;

struct HardlinkPath {
    infile: PathBuf,
    outfile: PathBuf,
}

struct HardlinkState {
    names: Vec<HardlinkPath>,
    source_ino: u64,
    mapped_ino: u32,
    nlink: u32,
    seen: u32,
}

struct DevState {
    dev: u64,
    hls: Vec<HardlinkState>,
}

struct ArchiveProperties {
    // first inode number to use. @ArchiveState.ino increments from this.
    initial_ino: u32,
    // if non-zero, then align file data segments to this offset by injecting
    // extra zeros after the filename string terminator.
    data_align: u32,
    // When injecting extra zeros into the filename field for data alignment,
    // ensure that it doesn't exceed this size. The linux kernel will ignore
    // files where namesize is larger than PATH_MAX, hence the need for this.
    namesize_max: u32,
    // if the archive is being appended to the end of an existing file, then
    // @initial_data_off is used when calculating @data_align alignment.
    initial_data_off: u64,
    // delimiter character for the stdin file list
    list_separator: u8,
    // mtime, uid and gid to use for archived inodes, instead of the value
    // reported by stat.
    fixed_mtime: Option<u32>,
    fixed_uid: Option<u32>,
    fixed_gid: Option<u32>,
    // When archiving a subset of hardlinks, nlink values in the archive can
    // represent the subset (renumber_nlink=true) or the original source file
    // nlink values (renumber_nlink=false), where the latter matches GNU cpio.
    renumber_nlink: bool,
    // If OUTPUT file exists, then zero-truncate it instead of appending. The
    // default append behaviour chains archives back-to-back, i.e. multiple
    // archives will be separated by a TRAILER and 512-byte padding.
    // See Linux's Documentation/driver-api/early-userspace/buffer-format.rst
    // for details on how chained initramfs archives are handled.
    truncate_existing: bool,
}

impl ArchiveProperties {
    pub fn default() -> ArchiveProperties {
        ArchiveProperties {
            initial_ino: 0, // match GNU cpio numbering
            data_align: 0,
            namesize_max: PATH_MAX as u32,
            initial_data_off: 0,
            list_separator: b'\n',
            fixed_mtime: None,
            fixed_uid: None,
            fixed_gid: None,
            renumber_nlink: false,
            truncate_existing: false,
        }
    }
}

struct ArchiveState {
    // 2d dev + inode vector serves two purposes:
    // - dev index provides reproducible major,minor values
    // - inode@dev provides hardlink state tracking
    ids: Vec<DevState>,
    // offset from the start of this archive
    off: u64,
    // next mapped inode number, used instead of source file inode numbers to
    // ensure reproducability. XXX: should track inode per mapped dev?
    ino: u32,
}

impl ArchiveState {
    pub fn new(ino_start: u32) -> ArchiveState {
        ArchiveState {
            ids: Vec::new(),
            off: 0,
            ino: ino_start,
        }
    }

    // lookup or create DevState for @dev. Return @major/@minor based on index
    pub fn dev_seen(&mut self, dev: u64) -> Option<(u32, u32)> {
        let index: u64 = match self.ids.iter().position(|i| i.dev == dev) {
            Some(idx) => idx.try_into().ok()?,
            None => {
                self.ids.push(DevState {
                    dev: dev,
                    hls: Vec::new(),
                });
                (self.ids.len() - 1).try_into().ok()?
            }
        };

        let major: u32 = (index >> 32).try_into().unwrap();
        let minor: u32 = (index & u64::from(u32::MAX)).try_into().unwrap();
        Some((major, minor))
    }

    // Check whether we've already seen this hardlink's dev/inode combination.
    // If already seen, fill the existing mapped_ino.
    // Return true if this entry has been deferred (seen != nlinks)
    pub fn hardlink_seen<W: Write + Seek>(
        &mut self,
        props: &ArchiveProperties,
        mut writer: W,
        major: u32,
        minor: u32,
        md: fs::Metadata,
        inpath: &Path,
        outpath: &Path,
        mapped_ino: &mut Option<u32>,
        mapped_nlink: &mut Option<u32>,
    ) -> std::io::Result<bool> {
        assert!(md.nlink() > 1);
        let index = u64::from(major) << 32 | u64::from(minor);
        // reverse index->major/minor conversion that was just done
        let devstate: &mut DevState = &mut self.ids[index as usize];
        let (_index, hl) = match devstate
            .hls
            .iter_mut()
            .enumerate()
            .find(|(_, hl)| hl.source_ino == md.ino())
        {
            Some(hl) => hl,
            None => {
                devstate.hls.push(HardlinkState {
                    names: vec![HardlinkPath {
                        infile: inpath.to_path_buf(),
                        outfile: outpath.to_path_buf(),
                    }],
                    source_ino: md.ino(),
                    mapped_ino: self.ino,
                    nlink: md.nlink().try_into().unwrap(), // pre-checked
                    seen: 1,
                });
                self.ino += 1; // ino is reserved for all subsequent links
                return Ok(true);
            }
        };

        if (*hl).names.iter().any(|n| n.infile == inpath) {
            println!(
                "duplicate hardlink path {} for {}",
                inpath.display(),
                md.ino()
            );
            // GNU cpio doesn't swallow duplicates
        }

        // hl.nlink may not match md.nlink if we've come here via
        // archive_flush_unseen_hardlinks() .

        (*hl).seen += 1;
        if (*hl).seen > (*hl).nlink {
            // GNU cpio powers through if a hardlink is listed multiple times,
            // exceeding nlink.
            println!("hardlink seen {} exceeds nlink {}", (*hl).seen, (*hl).nlink);
        }

        if (*hl).seen < (*hl).nlink {
            (*hl).names.push(HardlinkPath {
                infile: inpath.to_path_buf(),
                outfile: outpath.to_path_buf(),
            });
            return Ok(true);
        }

        // a new HardlinkPath entry isn't added, as return path handles cpio
        // outpath header *and* data segment.

        for path in (*hl).names.iter().rev() {
            dout!("writing hardlink {}", path.outfile.display());
            // length already PATH_MAX validated
            let fname = path.outfile.as_os_str().as_bytes();

            write!(
                writer,
                NEWC_HDR_FMT!(),
                magic = "070701",
                ino = (*hl).mapped_ino,
                mode = md.mode(),
                uid = match props.fixed_uid {
                    Some(u) => u,
                    None => md.uid(),
                },
                gid = match props.fixed_gid {
                    Some(g) => g,
                    None => md.gid(),
                },
                nlink = match props.renumber_nlink {
                    true => (*hl).nlink,
                    false => md.nlink().try_into().unwrap(),
                },
                mtime = match props.fixed_mtime {
                    Some(t) => t,
                    None => md.mtime().try_into().unwrap(),
                },
                filesize = 0,
                major = major,
                minor = major,
                rmajor = 0,
                rminor = 0,
                namesize = fname.len() + 1,
                chksum = 0
            )?;
            self.off += NEWC_HDR_LEN;
            writer.write_all(fname)?;
            self.off += fname.len() as u64;
            // +1 as padding starts after fname nulterm
            let seeklen = 1 + archive_padlen(self.off + 1, 4);
            writer.seek(io::SeekFrom::Current(seeklen as i64))?;
            self.off += seeklen;
        }
        *mapped_ino = Some((*hl).mapped_ino);
        // cpio nlink may be different to stat nlink if only a subset of links
        // are archived.
        if props.renumber_nlink {
            *mapped_nlink = Some((*hl).nlink);
        }

        // GNU cpio: if a name is given multiple times, exceeding nlink, then
        // subsequent names continue to be packed (with a repeat data segment),
        // using the same mapped inode.
        dout!("resetting hl at index {}", index);
        hl.seen = 0;
        hl.names.clear();

        return Ok(false);
    }
}

fn archive_path<W: Seek + Write>(
    state: &mut ArchiveState,
    props: &ArchiveProperties,
    path: &Path,
    mut writer: W,
) -> std::io::Result<()> {
    let inpath = path;
    let mut outpath = path.clone();
    let mut datalen: u32 = 0;
    let mut rmajor: u32 = 0;
    let mut rminor: u32 = 0;
    let mut hardlink_ino: Option<u32> = None;
    let mut hardlink_nlink: Option<u32> = None;
    let mut symlink_tgt = PathBuf::new();
    let mut data_align_seek: u32 = 0;

    outpath = match outpath.strip_prefix("./") {
        Ok(p) => {
            if p.as_os_str().as_bytes().len() == 0 {
                outpath // retain './' and '.' paths
            } else {
                p
            }
        }
        Err(_) => outpath,
    };
    let fname = outpath.as_os_str().as_bytes();
    if fname.len() + 1 >= PATH_MAX.try_into().unwrap() {
        return Err(io::Error::new(io::ErrorKind::InvalidInput, "path too long"));
    }

    let md = match fs::symlink_metadata(inpath) {
        Ok(m) => m,
        Err(e) => {
            println!("failed to get metadata for {}: {}", inpath.display(), e);
            return Err(e);
        }
    };
    dout!("archiving {} with mode {:o}", outpath.display(), md.mode());

    let (major, minor) = match state.dev_seen(md.dev()) {
        Some((maj, min)) => (maj, min),
        None => return Err(io::Error::new(io::ErrorKind::Other, "failed to map dev")),
    };

    if md.nlink() > u32::MAX as u64 {
        return Err(io::Error::new(
            io::ErrorKind::InvalidInput,
            "nlink too large",
        ));
    }

    let mtime: u32 = match props.fixed_mtime {
        Some(t) => t,
        None => {
            // check for 2106 epoch overflow
            if md.mtime() > i64::from(u32::MAX) {
                return Err(io::Error::new(
                    io::ErrorKind::InvalidInput,
                    "mtime too large for cpio",
                ));
            }
            md.mtime().try_into().unwrap()
        }
    };

    let ftype = md.file_type();
    if ftype.is_symlink() {
        symlink_tgt = fs::read_link(inpath)?;
        datalen = {
            let d: usize = symlink_tgt.as_os_str().as_bytes().len();
            if d >= PATH_MAX.try_into().unwrap() {
                return Err(io::Error::new(
                    io::ErrorKind::InvalidInput,
                    "symlink path too long",
                ));
            }
            d.try_into().unwrap()
        };
        // no zero terminator for symlink target path
    }

    if ftype.is_block_device() || ftype.is_char_device() {
        rmajor = (md.rdev() >> 8) as u32;
        rminor = (md.rdev() & 0xff) as u32;
    }

    if ftype.is_file() {
        datalen = {
            if md.len() > u64::from(u32::MAX) {
                return Err(io::Error::new(
                    io::ErrorKind::InvalidInput,
                    "file too large for newc",
                ));
            }
            md.len().try_into().unwrap()
        };

        if md.nlink() > 1 {
            // follow GNU cpio's behaviour of attaching hardlink data only to
            // the last entry in the archive.
            let deferred = state.hardlink_seen(
                &props,
                &mut writer,
                major,
                minor,
                md.clone(),
                &inpath,
                outpath,
                &mut hardlink_ino,
                &mut hardlink_nlink,
            )?;
            if deferred {
                dout!("deferring hardlink {} data portion", outpath.display());
                return Ok(());
            }
        }

        if props.data_align > 0 && datalen > props.data_align {
            // XXX we're "bending" the newc spec a bit here to inject zeros
            // after fname to provide data segment alignment. These zeros are
            // accounted for in the namesize, but some applications may only
            // expect a single zero-terminator (and 4 byte alignment). GNU cpio
            // and Linux initramfs handle this fine as long as PATH_MAX isn't
            // exceeded.
            data_align_seek = {
                let len: u64 = archive_padlen(
                    props.initial_data_off + state.off + NEWC_HDR_LEN + fname.len() as u64 + 1,
                    u64::from(props.data_align),
                );
                let padded_namesize = len + fname.len() as u64 + 1;
                if padded_namesize > u64::from(props.namesize_max) {
                    dout!(
                        "{} misaligned. Required padding {} exceeds namesize maximum {}.",
                        outpath.display(),
                        len,
                        props.namesize_max
                    );
                    0
                } else {
                    len.try_into().unwrap()
                }
            };
        }
    }

    write!(
        writer,
        NEWC_HDR_FMT!(),
        magic = "070701",
        ino = match hardlink_ino {
            Some(i) => i,
            None => {
                let i = state.ino;
                state.ino += 1;
                i
            }
        },
        mode = md.mode(),
        uid = match props.fixed_uid {
            Some(u) => u,
            None => md.uid(),
        },
        gid = match props.fixed_gid {
            Some(g) => g,
            None => md.gid(),
        },
        nlink = match hardlink_nlink {
            Some(n) => n,
            None => md.nlink().try_into().unwrap(),
        },
        mtime = mtime,
        filesize = datalen,
        major = major,
        minor = major,
        rmajor = rmajor,
        rminor = rminor,
        namesize = fname.len() + 1 + data_align_seek as usize,
        chksum = 0
    )?;
    state.off += NEWC_HDR_LEN;

    writer.write_all(fname)?;
    state.off += fname.len() as u64;

    let mut seek_len: i64 = 1; // fname nulterm
    if data_align_seek > 0 {
        seek_len += data_align_seek as i64;
        assert_eq!(archive_padlen(state.off + seek_len as u64, 4), 0);
    } else {
        let padding_len = archive_padlen(state.off + seek_len as u64, 4);
        seek_len += padding_len as i64;
    }
    writer.seek(io::SeekFrom::Current(seek_len))?;
    state.off += seek_len as u64;

    // io::copy() can reflink: https://github.com/rust-lang/rust/pull/75272 \o/
    if datalen > 0 {
        if ftype.is_file() {
            let mut reader = io::BufReader::new(fs::File::open(inpath)?);
            let copied = io::copy(&mut reader, &mut writer)?;
            if copied != u64::from(datalen) {
                return Err(io::Error::new(
                    io::ErrorKind::UnexpectedEof,
                    "copy returned unexpected length",
                ));
            }
        } else if ftype.is_symlink() {
            writer.write_all(symlink_tgt.as_os_str().as_bytes())?;
        }
        state.off += u64::from(datalen);
        let dpad_len: usize = archive_padlen(state.off, 4).try_into().unwrap();
        write!(writer, "{pad:.padlen$}", padlen = dpad_len, pad = "\0\0\0")?;
        state.off += dpad_len as u64;
    }

    Ok(())
}

fn archive_padlen(off: u64, alignment: u64) -> u64 {
    (alignment - (off & (alignment - 1))) % alignment
}

// this fn is inefficient, but optimizing for hardlinks isn't high priority
fn archive_flush_unseen_hardlinks<W: Write + Seek>(
    state: &mut ArchiveState,
    props: &ArchiveProperties,
    mut writer: W,
) -> std::io::Result<()> {
    let mut deferred_inpaths: Vec<PathBuf> = Vec::new();
    for id in state.ids.iter_mut() {
        for hl in id.hls.iter_mut() {
            if hl.seen == 0 || hl.seen == hl.nlink {
                dout!("HardlinkState complete with seen {}", hl.seen);
                continue;
            }
            dout!(
                "pending HardlinkState with seen {} != nlinks {}",
                hl.seen,
                hl.nlink
            );

            while hl.names.len() > 0 {
                let path = hl.names.pop().unwrap();
                deferred_inpaths.push(path.infile);
            }
            // ensure that data segment gets added on archive_path recall
            hl.nlink = hl.seen;
            hl.seen = 0;
            // existing allocated inode should be used
        }
    }

    if deferred_inpaths.len() > 0 {
        // rotate-right to match gnu ordering
        deferred_inpaths.rotate_right(1);

        // .reverse() to match gnu ordering
        for p in deferred_inpaths.iter().rev() {
            archive_path(state, props, p.as_path(), &mut writer)?;
        }
    }

    Ok(())
}

fn archive_trailer<W: Write>(mut writer: W, cur_off: u64) -> std::io::Result<u64> {
    let fname = "TRAILER!!!";
    let fname_len = fname.len() + 1;

    write!(
        writer,
        NEWC_HDR_FMT!(),
        magic = "070701",
        ino = 0,
        mode = 0,
        uid = 0,
        gid = 0,
        nlink = 1,
        mtime = 0,
        filesize = 0,
        major = 0,
        minor = 0,
        rmajor = 0,
        rminor = 0,
        namesize = fname_len,
        chksum = 0
    )?;
    let mut off: u64 = cur_off + NEWC_HDR_LEN;

    let padding_len = archive_padlen(off + fname_len as u64, 4);
    write!(
        writer,
        "{}\0{pad:.padlen$}",
        fname,
        padlen = padding_len as usize,
        pad = "\0\0\0"
    )?;
    off += fname_len as u64 + padding_len as u64;

    Ok(off)
}

fn archive_loop<R: BufRead, W: Seek + Write>(
    mut reader: R,
    mut writer: W,
    props: &ArchiveProperties,
) -> std::io::Result<u64> {
    if props.data_align > 0 && (props.initial_data_off + u64::from(props.data_align)) % 4 != 0 {
        // must satisfy both data_align and cpio 4-byte padding alignment
        return Err(io::Error::new(
            io::ErrorKind::InvalidInput,
            "data alignment must be a multiple of 4",
        ));
    }

    let mut state = ArchiveState::new(props.initial_ino);
    loop {
        let mut linebuf: Vec<u8> = Vec::new();
        let mut r = reader.by_ref().take(PATH_MAX);
        match r.read_until(props.list_separator, &mut linebuf) {
            Ok(l) => {
                if l == 0 {
                    break; // EOF
                }
                if l >= PATH_MAX.try_into().unwrap() {
                    return Err(io::Error::new(io::ErrorKind::InvalidInput, "path too long"));
                }
            }
            Err(e) => {
                println!("read_until() failed: {}", e);
                return Err(e);
            }
        };

        // trim separator. len > 0 already checked.
        let last_byte = linebuf.last().unwrap();
        if *last_byte == props.list_separator {
            linebuf.pop().unwrap();
            if linebuf.len() == 0 {
                continue;
            }
        } else {
            println!(
                "\'{:0x}\' ending not separator \'{:0x}\' terminated",
                last_byte, props.list_separator
            );
        }

        let linestr = OsStr::from_bytes(linebuf.as_slice());
        let path = Path::new(linestr);
        archive_path(&mut state, props, path, &mut writer)?;
    }
    archive_flush_unseen_hardlinks(&mut state, props, &mut writer)?;
    state.off = archive_trailer(&mut writer, state.off)?;

    // GNU cpio pads the end of an archive out to blocklen with zeros
    let block_padlen = archive_padlen(state.off, 512);
    if block_padlen > 0 {
        let z = vec![0u8; block_padlen.try_into().unwrap()];
        writer.write_all(&z)?;
        state.off += block_padlen;
    }
    writer.flush()?;

    Ok(state.off)
}

fn params_usage(params: &[Argument]) {
    argument::print_help("dracut-cpio", "OUTPUT", params);
    println!("\nExample: find fs-tree/ | dracut-cpio archive.cpio\n");
}

fn params_process(props: &mut ArchiveProperties) -> argument::Result<PathBuf> {
    let params = &[
        Argument::positional("OUTPUT", "Write cpio archive to this file path."),
        Argument::value(
            "data-align",
            "ALIGNMENT",
            "Attempt to pad archive to achieve ALIGNMENT for file data.",
        ),
        Argument::short_flag(
            '0',
            "null",
            "Expect null delimeters in stdin filename list instead of newline.",
        ),
        Argument::value(
            "mtime",
            "EPOCH",
            "Use EPOCH for archived mtime instead of filesystem reported values.",
        ),
        Argument::value(
            "owner",
            "UID:GID",
            "Use UID and GID instead of filesystem reported owner values.",
        ),
        Argument::flag(
            "truncate-existing",
            "Truncate and overwrite any existing OUTPUT file, instead of appending.",
        ),
        Argument::short_flag('h', "help", "Print help message."),
    ];

    let mut positional_args = 0;
    let args = env::args().skip(1); // skip binary name
    let match_res = argument::set_arguments(args, params, |name, value| {
        match name {
            "" => positional_args += 1,
            "data-align" => {
                let v: u32 = value
                    .unwrap()
                    .parse()
                    .map_err(|_| argument::Error::InvalidValue {
                        value: value.unwrap().to_owned(),
                        expected: String::from("data-align must be an integer"),
                    })?;
                if v > props.namesize_max {
                    println!(
                        concat!(
                            "Requested data-align {} larger than namesize maximum {}.",
                            " This will likely result in misalignment."
                        ),
                        v, props.namesize_max
                    );
                }
                props.data_align = v;
            }
            "null" => props.list_separator = b'\0',
            "mtime" => {
                let v: u32 = value
                    .unwrap()
                    .parse()
                    .map_err(|_| argument::Error::InvalidValue {
                        value: value.unwrap().to_owned(),
                        expected: String::from("mtime must be an integer"),
                    })?;
                props.fixed_mtime = Some(v);
            }
            "owner" => {
                let ugv_parsed: argument::Result<Vec<u32>> = value
                    .unwrap()
                    .split(':')
                    .map(|id| {
                        id.parse().map_err(|_| argument::Error::InvalidValue {
                            value: id.to_owned(),
                            expected: String::from("uid/gid must be an integer"),
                        })
                    })
                    .collect();

                let ugv_parsed = ugv_parsed?;
                if ugv_parsed.len() != 2 {
                    return Err(argument::Error::InvalidValue {
                        value: value.unwrap().to_owned(),
                        expected: String::from("owner must be UID:GID"),
                    });
                }
                props.fixed_uid = Some(ugv_parsed[0]);
                props.fixed_gid = Some(ugv_parsed[1]);
            }
            "truncate-existing" => props.truncate_existing = true,
            "help" => return Err(argument::Error::PrintHelp),
            _ => unreachable!(),
        };
        Ok(())
    });

    match match_res {
        Ok(_) => {
            if positional_args != 1 {
                params_usage(params);
                return Err(argument::Error::ExpectedArgument(
                    "one OUTPUT parameter required".to_string(),
                ));
            }
        }
        Err(e) => {
            params_usage(params);
            return Err(e);
        }
    }

    let last_arg = env::args_os().last().unwrap();
    Ok(PathBuf::from(&last_arg))
}

fn main() -> std::io::Result<()> {
    let mut props = ArchiveProperties::default();
    let output_path = match params_process(&mut props) {
        Ok(p) => p,
        Err(argument::Error::PrintHelp) => return Ok(()),
        Err(e) => return Err(io::Error::new(io::ErrorKind::InvalidInput, e.to_string())),
    };

    let mut f = fs::OpenOptions::new()
        .read(false)
        .write(true)
        .create(true)
        .truncate(props.truncate_existing)
        .open(&output_path)?;
    if !props.truncate_existing {
        props.initial_data_off = f.seek(io::SeekFrom::End(0))?;
    }
    let mut writer = io::BufWriter::new(f);

    let stdin = std::io::stdin();
    let mut reader = io::BufReader::new(stdin);

    let _wrote = archive_loop(&mut reader, &mut writer, &props)?;

    if props.initial_data_off > 0 {
        dout!(
            "appended {} bytes to archive {} at offset {}",
            _wrote,
            output_path.display(),
            props.initial_data_off
        );
    } else {
        dout!(
            "wrote {} bytes to archive {}",
            _wrote,
            output_path.display()
        );
    }

    Ok(())
}

// tests change working directory, so need to be run with --test-threads=1
#[cfg(test)]
mod tests {
    use super::*;
    use std::cmp;
    use std::os::unix::fs as unixfs;
    use std::path::PathBuf;
    use std::process::{Command, Stdio};

    struct TempWorkDir {
        prev_dir: PathBuf,
        parent_tmp_dir: PathBuf,
        cleanup_files: Vec<PathBuf>,
        cleanup_dirs: Vec<PathBuf>,
        ignore_cleanup: bool, // useful for debugging
    }

    impl TempWorkDir {
        // create a temporary directory under CWD and cd into it.
        // The directory will be cleaned up when twd goes out of scope.
        pub fn new() -> TempWorkDir {
            let mut buf = [0u8; 16];
            let mut s = String::from("cpio-selftest-");
            fs::File::open("/dev/urandom")
                .unwrap()
                .read_exact(&mut buf)
                .unwrap();
            for i in &buf {
                s.push_str(&format!("{:02x}", i).to_string());
            }
            let mut twd = TempWorkDir {
                prev_dir: env::current_dir().unwrap(),
                parent_tmp_dir: {
                    let mut t = env::current_dir().unwrap().clone();
                    t.push(s);
                    println!("parent_tmp_dir: {}", t.display());
                    t
                },
                cleanup_files: Vec::new(),
                cleanup_dirs: Vec::new(),
                ignore_cleanup: false,
            };
            fs::create_dir(&twd.parent_tmp_dir).unwrap();
            twd.cleanup_dirs.push(twd.parent_tmp_dir.clone());
            env::set_current_dir(&twd.parent_tmp_dir).unwrap();

            twd
        }

        pub fn create_tmp_file(&mut self, name: &str, len_bytes: u64) {
            let mut bytes = len_bytes;
            let f = fs::File::create(name).unwrap();
            self.cleanup_files.push(PathBuf::from(name));
            let mut writer = io::BufWriter::new(f);
            let mut buf = [0u8; 512];

            for (i, elem) in buf.iter_mut().enumerate() {
                *elem = !(i & 0xFF) as u8;
            }

            while bytes > 0 {
                let this_len = cmp::min(buf.len(), bytes.try_into().unwrap());
                writer.write_all(&buf[0..this_len]).unwrap();
                bytes -= this_len as u64;
            }

            writer.flush().unwrap();
        }

        pub fn create_tmp_dir(&mut self, name: &str) {
            fs::create_dir(name).unwrap();
            self.cleanup_dirs.push(PathBuf::from(name));
        }
    }

    impl Drop for TempWorkDir {
        fn drop(&mut self) {
            for f in self.cleanup_files.iter().rev() {
                if self.ignore_cleanup {
                    println!("ignoring cleanup of file {}", f.display());
                    continue;
                }
                println!("cleaning up test file at {}", f.display());
                match fs::remove_file(f) {
                    Err(e) => println!("file removal failed {}", e),
                    Ok(_) => {}
                };
            }
            for f in self.cleanup_dirs.iter().rev() {
                if self.ignore_cleanup {
                    println!("ignoring cleanup of dir {}", f.display());
                    continue;
                }
                println!("cleaning up test dir at {}", f.display());
                match fs::remove_dir(f) {
                    Err(e) => println!("dir removal failed {}", e),
                    Ok(_) => {}
                };
            }
            println!("returning cwd to {}", self.prev_dir.display());
            env::set_current_dir(self.prev_dir.as_path()).unwrap();
        }
    }

    fn gnu_cpio_create(stdinput: &[u8], out: &str) {
        let mut proc = Command::new("cpio")
            .args(&["--quiet", "-o", "-H", "newc", "--reproducible", "-F", out])
            .stdin(Stdio::piped())
            .spawn()
            .expect("GNU cpio failed to start");
        {
            let mut stdin = proc.stdin.take().unwrap();
            stdin.write_all(stdinput).expect("Failed to write to stdin");
        }

        let status = proc.wait().unwrap();
        assert!(status.success());
    }

    #[test]
    fn test_archive_empty_file() {
        let mut twd = TempWorkDir::new();
        twd.create_tmp_file("file.txt", 0);

        gnu_cpio_create("file.txt\n".as_bytes(), "gnu.cpio");
        twd.cleanup_files.push(PathBuf::from("gnu.cpio"));

        // use dracut-cpio to archive file.txt
        let f = fs::File::create("dracut.cpio").unwrap();
        let mut writer = io::BufWriter::new(f);
        let mut reader = io::BufReader::new("file.txt\n".as_bytes());
        let wrote = archive_loop(&mut reader, &mut writer, &ArchiveProperties::default()).unwrap();
        twd.cleanup_files.push(PathBuf::from("dracut.cpio"));
        assert_eq!(wrote, 512);

        let status = Command::new("diff")
            .args(&["gnu.cpio", "dracut.cpio"])
            .status()
            .expect("diff failed to start");
        assert!(status.success());
    }

    #[test]
    fn test_archive_small_file() {
        let mut twd = TempWorkDir::new();
        twd.create_tmp_file("file.txt", 33);

        gnu_cpio_create("file.txt\n".as_bytes(), "gnu.cpio");
        twd.cleanup_files.push(PathBuf::from("gnu.cpio"));

        let f = fs::File::create("dracut.cpio").unwrap();
        let mut writer = io::BufWriter::new(f);
        let mut reader = io::BufReader::new("file.txt\n".as_bytes());
        let wrote = archive_loop(&mut reader, &mut writer, &ArchiveProperties::default()).unwrap();
        twd.cleanup_files.push(PathBuf::from("dracut.cpio"));
        assert!(wrote > NEWC_HDR_LEN * 2 + 33);

        let status = Command::new("diff")
            .args(&["gnu.cpio", "dracut.cpio"])
            .status()
            .expect("diff failed to start");
        assert!(status.success());
    }

    #[test]
    fn test_archive_prefixed_path() {
        let mut twd = TempWorkDir::new();
        twd.create_tmp_file("file.txt", 0);

        gnu_cpio_create("./file.txt\n".as_bytes(), "gnu.cpio");
        twd.cleanup_files.push(PathBuf::from("gnu.cpio"));

        let f = fs::File::create("dracut.cpio").unwrap();
        let mut writer = io::BufWriter::new(f);
        let mut reader = io::BufReader::new("./file.txt\n".as_bytes());
        let wrote = archive_loop(&mut reader, &mut writer, &ArchiveProperties::default()).unwrap();
        twd.cleanup_files.push(PathBuf::from("dracut.cpio"));
        assert_eq!(wrote, 512);

        let status = Command::new("diff")
            .args(&["gnu.cpio", "dracut.cpio"])
            .status()
            .expect("diff failed to start");
        assert!(status.success());
    }

    #[test]
    fn test_archive_absolute_path() {
        let mut twd = TempWorkDir::new();
        twd.create_tmp_file("file.txt", 0);

        let canon_path = fs::canonicalize("file.txt").unwrap();
        let mut canon_file_list = canon_path.into_os_string();
        canon_file_list.push("\n");

        gnu_cpio_create(canon_file_list.as_bytes(), "gnu.cpio");
        twd.cleanup_files.push(PathBuf::from("gnu.cpio"));

        let f = fs::File::create("dracut.cpio").unwrap();
        let mut writer = io::BufWriter::new(f);
        let mut reader = io::BufReader::new(canon_file_list.as_bytes());
        let wrote = archive_loop(&mut reader, &mut writer, &ArchiveProperties::default()).unwrap();
        twd.cleanup_files.push(PathBuf::from("dracut.cpio"));
        assert_eq!(wrote, 512);

        let status = Command::new("diff")
            .args(&["gnu.cpio", "dracut.cpio"])
            .status()
            .expect("diff failed to start");
        assert!(status.success());
    }

    #[test]
    fn test_archive_dir() {
        let mut twd = TempWorkDir::new();
        twd.create_tmp_dir("dir");

        gnu_cpio_create("dir\n".as_bytes(), "gnu.cpio");
        twd.cleanup_files.push(PathBuf::from("gnu.cpio"));

        let f = fs::File::create("dracut.cpio").unwrap();
        let mut writer = io::BufWriter::new(f);
        let mut reader = io::BufReader::new("dir\n".as_bytes());
        let wrote = archive_loop(&mut reader, &mut writer, &ArchiveProperties::default()).unwrap();
        twd.cleanup_files.push(PathBuf::from("dracut.cpio"));
        assert_eq!(wrote, 512);

        let status = Command::new("diff")
            .args(&["gnu.cpio", "dracut.cpio"])
            .status()
            .expect("diff failed to start");
        assert!(status.success());
    }

    #[test]
    fn test_archive_dir_file() {
        let mut twd = TempWorkDir::new();
        twd.create_tmp_dir("dir");
        twd.create_tmp_file("dir/file.txt", 512 * 32);
        let file_list: &str = "dir\n\ndir/file.txt\n"; // double separator

        gnu_cpio_create(file_list.as_bytes(), "gnu.cpio");
        twd.cleanup_files.push(PathBuf::from("gnu.cpio"));

        let f = fs::File::create("dracut.cpio").unwrap();
        let mut writer = io::BufWriter::new(f);
        let mut reader = io::BufReader::new(file_list.as_bytes());
        let wrote = archive_loop(&mut reader, &mut writer, &ArchiveProperties::default()).unwrap();
        twd.cleanup_files.push(PathBuf::from("dracut.cpio"));
        assert!(wrote > NEWC_HDR_LEN * 3 + 512 * 32);

        let status = Command::new("diff")
            .args(&["gnu.cpio", "dracut.cpio"])
            .status()
            .expect("diff failed to start");
        assert!(status.success());
    }

    #[test]
    fn test_archive_dot_path() {
        let mut twd = TempWorkDir::new();
        twd.create_tmp_dir("dir");
        twd.create_tmp_file("dir/file.txt", 512 * 32);
        let file_list: &str = ".\ndir\ndir/file.txt\n";

        gnu_cpio_create(file_list.as_bytes(), "gnu.cpio");
        twd.cleanup_files.push(PathBuf::from("gnu.cpio"));

        let f = fs::File::create("dracut.cpio").unwrap();
        let mut writer = io::BufWriter::new(f);
        let mut reader = io::BufReader::new(file_list.as_bytes());
        let wrote = archive_loop(&mut reader, &mut writer, &ArchiveProperties::default()).unwrap();
        twd.cleanup_files.push(PathBuf::from("dracut.cpio"));
        assert!(wrote > NEWC_HDR_LEN * 4 + 512 * 32);

        let status = Command::new("diff")
            .args(&["gnu.cpio", "dracut.cpio"])
            .status()
            .expect("diff failed to start");
        assert!(status.success());
    }

    #[test]
    fn test_archive_dot_slash_path() {
        let mut twd = TempWorkDir::new();
        twd.create_tmp_dir("dir");
        twd.create_tmp_file("dir/file.txt", 512 * 32);
        let file_list: &str = "./\ndir\ndir/file.txt\n";

        gnu_cpio_create(file_list.as_bytes(), "gnu.cpio");
        twd.cleanup_files.push(PathBuf::from("gnu.cpio"));

        let f = fs::File::create("dracut.cpio").unwrap();
        let mut writer = io::BufWriter::new(f);
        let mut reader = io::BufReader::new(file_list.as_bytes());
        let wrote = archive_loop(&mut reader, &mut writer, &ArchiveProperties::default()).unwrap();
        twd.cleanup_files.push(PathBuf::from("dracut.cpio"));
        assert!(wrote > NEWC_HDR_LEN * 4 + 512 * 32);

        let status = Command::new("diff")
            .args(&["gnu.cpio", "dracut.cpio"])
            .status()
            .expect("diff failed to start");
        assert!(status.success());
    }

    #[test]
    fn test_archive_symlink() {
        let mut twd = TempWorkDir::new();
        twd.create_tmp_file("file.txt", 0);
        unixfs::symlink("file.txt", "symlink.txt").unwrap();
        twd.cleanup_files.push(PathBuf::from("symlink.txt"));

        gnu_cpio_create("file.txt\nsymlink.txt\n".as_bytes(), "gnu.cpio");
        twd.cleanup_files.push(PathBuf::from("gnu.cpio"));

        let f = fs::File::create("dracut.cpio").unwrap();
        let mut writer = io::BufWriter::new(f);
        let mut reader = io::BufReader::new("file.txt\nsymlink.txt\n".as_bytes());
        let wrote = archive_loop(&mut reader, &mut writer, &ArchiveProperties::default()).unwrap();
        twd.cleanup_files.push(PathBuf::from("dracut.cpio"));
        assert_eq!(wrote, 512);

        let status = Command::new("diff")
            .args(&["gnu.cpio", "dracut.cpio"])
            .status()
            .expect("diff failed to start");
        assert!(status.success());
    }

    #[test]
    fn test_archive_fifo() {
        let mut twd = TempWorkDir::new();

        // mknod [OPTION]... NAME TYPE [MAJOR MINOR]
        let mut proc = Command::new("mknod")
            .args(&["fifo", "p"])
            .spawn()
            .expect("mknod failed to start");
        assert!(proc.wait().unwrap().success());
        twd.cleanup_files.push(PathBuf::from("fifo"));

        gnu_cpio_create("fifo\n".as_bytes(), "gnu.cpio");
        twd.cleanup_files.push(PathBuf::from("gnu.cpio"));

        let f = fs::File::create("dracut.cpio").unwrap();
        let mut writer = io::BufWriter::new(f);
        let mut reader = io::BufReader::new("fifo\n".as_bytes());
        let wrote = archive_loop(&mut reader, &mut writer, &ArchiveProperties::default()).unwrap();
        twd.cleanup_files.push(PathBuf::from("dracut.cpio"));
        assert_eq!(wrote, 512);

        let status = Command::new("diff")
            .args(&["gnu.cpio", "dracut.cpio"])
            .status()
            .expect("diff failed to start");
        assert!(status.success());
    }

    #[test]
    fn test_archive_char() {
        let mut twd = TempWorkDir::new();

        gnu_cpio_create("/dev/zero\n".as_bytes(), "gnu.cpio");
        twd.cleanup_files.push(PathBuf::from("gnu.cpio"));

        let f = fs::File::create("dracut.cpio").unwrap();
        let mut writer = io::BufWriter::new(f);
        let mut reader = io::BufReader::new("/dev/zero\n".as_bytes());
        let wrote = archive_loop(&mut reader, &mut writer, &ArchiveProperties::default()).unwrap();
        twd.cleanup_files.push(PathBuf::from("dracut.cpio"));
        assert_eq!(wrote, 512);

        let status = Command::new("diff")
            .args(&["gnu.cpio", "dracut.cpio"])
            .status()
            .expect("diff failed to start");
        assert!(status.success());
    }

    #[test]
    fn test_archive_data_align() {
        let mut twd = TempWorkDir::new();
        twd.create_tmp_dir("dir");
        twd.create_tmp_file("dir/file.txt", 1024 * 1024); // 1M

        twd.create_tmp_dir("extractor");
        let f = fs::File::create("extractor/dracut.cpio").unwrap();
        let mut writer = io::BufWriter::new(f);
        let mut reader = io::BufReader::new("dir\ndir/file.txt\n".as_bytes());
        // 4k cpio data segment alignment injects zeros after filename nullterm
        let wrote = archive_loop(
            &mut reader,
            &mut writer,
            &ArchiveProperties {
                data_align: 4096,
                ..ArchiveProperties::default()
            },
        )
        .unwrap();
        twd.cleanup_files
            .push(PathBuf::from("extractor/dracut.cpio"));
        assert!(wrote > NEWC_HDR_LEN * 3 + 1024 * 1024);

        // check 4k data segment alignment
        let mut proc = Command::new("diff")
            .args(&["dir/file.txt", "-"])
            .stdin(Stdio::piped())
            .spawn()
            .expect("diff failed to start");
        {
            let f = fs::File::open("extractor/dracut.cpio").unwrap();
            let mut reader = io::BufReader::new(f);
            reader.seek(io::SeekFrom::Start(4096)).unwrap();
            let mut take = reader.take(1024 * 1024 as u64);
            let mut stdin = proc.stdin.take().unwrap();
            let copied = io::copy(&mut take, &mut stdin).unwrap();
            assert_eq!(copied, 1024 * 1024);
        }
        let status = proc.wait().unwrap();
        assert!(status.success());

        // confirm that GNU cpio can extract fname-zeroed paths
        let status = Command::new("cpio")
            .current_dir("extractor")
            .args(&["--quiet", "-i", "-H", "newc", "-F", "dracut.cpio"])
            .status()
            .expect("GNU cpio failed to start");
        assert!(status.success());
        twd.cleanup_files
            .push(PathBuf::from("extractor/dir/file.txt"));
        twd.cleanup_dirs.push(PathBuf::from("extractor/dir"));

        let status = Command::new("diff")
            .args(&["dir/file.txt", "extractor/dir/file.txt"])
            .status()
            .expect("diff failed to start");
        assert!(status.success());
    }

    #[test]
    fn test_archive_data_align_off() {
        let mut twd = TempWorkDir::new();
        twd.create_tmp_dir("dir1");
        twd.create_tmp_dir("dir2");
        twd.create_tmp_dir("dir3");
        twd.create_tmp_file("dir1/file.txt", 514 * 1024);

        twd.create_tmp_dir("extractor");
        let data_before_cpio = [5u8; 16384 + 4];
        let f = fs::File::create("extractor/dracut.cpio").unwrap();
        twd.cleanup_files
            .push(PathBuf::from("extractor/dracut.cpio"));
        let mut writer = io::BufWriter::new(f);
        writer.write_all(&data_before_cpio).unwrap();
        let mut reader = io::BufReader::new("dir1\ndir2\ndir3\ndir1/file.txt\n".as_bytes());
        let wrote = archive_loop(
            &mut reader,
            &mut writer,
            &ArchiveProperties {
                data_align: 4096,
                initial_data_off: data_before_cpio.len() as u64,
                ..ArchiveProperties::default()
            },
        )
        .unwrap();
        assert!(wrote > NEWC_HDR_LEN * 5 + 514 * 1024);

        let mut proc = Command::new("diff")
            .args(&["dir1/file.txt", "-"])
            .stdin(Stdio::piped())
            .spawn()
            .expect("diff failed to start");
        {
            let f = fs::File::open("extractor/dracut.cpio").unwrap();
            let mut reader = io::BufReader::new(f);
            reader.seek(io::SeekFrom::Start(16384 + 4096)).unwrap();
            let mut take = reader.take(514 * 1024 as u64);
            let mut stdin = proc.stdin.take().unwrap();
            let copied = io::copy(&mut take, &mut stdin).unwrap();
            assert_eq!(copied, 514 * 1024);
        }
        let status = proc.wait().unwrap();
        assert!(status.success());
    }

    #[test]
    fn test_archive_data_align_off_bad() {
        let mut twd = TempWorkDir::new();
        twd.create_tmp_file("file.txt", 514 * 1024);

        let data_before_cpio = [5u8; 16384 + 3];
        let f = fs::File::create("dracut.cpio").unwrap();
        twd.cleanup_files.push(PathBuf::from("dracut.cpio"));
        let mut writer = io::BufWriter::new(f);
        writer.write_all(&data_before_cpio).unwrap();
        let mut reader = io::BufReader::new("file.txt\n".as_bytes());
        let res = archive_loop(
            &mut reader,
            &mut writer,
            &ArchiveProperties {
                data_align: 4096,
                initial_data_off: data_before_cpio.len() as u64,
                ..ArchiveProperties::default()
            },
        );
        assert!(res.is_err());
        assert_eq!(io::ErrorKind::InvalidInput, res.unwrap_err().kind());
    }

    #[test]
    fn test_archive_hardlinks_order() {
        let mut twd = TempWorkDir::new();
        twd.create_tmp_file("file.txt", 512 * 4);
        fs::hard_link("file.txt", "link1.txt").unwrap();
        twd.cleanup_files.push(PathBuf::from("link1.txt"));
        fs::hard_link("file.txt", "link2.txt").unwrap();
        twd.cleanup_files.push(PathBuf::from("link2.txt"));
        twd.create_tmp_file("another.txt", 512 * 4);
        let file_list: &str = "file.txt\nanother.txt\nlink1.txt\nlink2.txt\n";

        gnu_cpio_create(file_list.as_bytes(), "gnu.cpio");
        twd.cleanup_files.push(PathBuf::from("gnu.cpio"));

        let f = fs::File::create("dracut.cpio").unwrap();
        let mut writer = io::BufWriter::new(f);
        let mut reader = io::BufReader::new(file_list.as_bytes());
        let wrote = archive_loop(&mut reader, &mut writer, &ArchiveProperties::default()).unwrap();
        twd.cleanup_files.push(PathBuf::from("dracut.cpio"));
        assert!(wrote > NEWC_HDR_LEN * 5 + 512 * 8);

        let status = Command::new("diff")
            .args(&["gnu.cpio", "dracut.cpio"])
            .status()
            .expect("diff failed to start");
        assert!(status.success());
    }

    #[test]
    fn test_archive_hardlinks_empty() {
        let mut twd = TempWorkDir::new();
        twd.create_tmp_file("file.txt", 0);
        fs::hard_link("file.txt", "link1.txt").unwrap();
        twd.cleanup_files.push(PathBuf::from("link1.txt"));
        fs::hard_link("file.txt", "link2.txt").unwrap();
        twd.cleanup_files.push(PathBuf::from("link2.txt"));
        twd.create_tmp_file("another.txt", 512 * 4);
        let file_list: &str = "file.txt\nanother.txt\nlink1.txt\nlink2.txt\n";

        gnu_cpio_create(file_list.as_bytes(), "gnu.cpio");
        twd.cleanup_files.push(PathBuf::from("gnu.cpio"));

        let f = fs::File::create("dracut.cpio").unwrap();
        let mut writer = io::BufWriter::new(f);
        let mut reader = io::BufReader::new(file_list.as_bytes());
        let wrote = archive_loop(&mut reader, &mut writer, &ArchiveProperties::default()).unwrap();
        twd.cleanup_files.push(PathBuf::from("dracut.cpio"));
        assert!(wrote > NEWC_HDR_LEN * 5 + 512 * 4);

        let status = Command::new("diff")
            .args(&["gnu.cpio", "dracut.cpio"])
            .status()
            .expect("diff failed to start");
        assert!(status.success());
    }

    #[test]
    fn test_archive_hardlinks_missing() {
        let mut twd = TempWorkDir::new();
        twd.create_tmp_file("file.txt", 512 * 4);
        fs::hard_link("file.txt", "link1.txt").unwrap();
        twd.cleanup_files.push(PathBuf::from("link1.txt"));
        fs::hard_link("file.txt", "link2.txt").unwrap();
        twd.cleanup_files.push(PathBuf::from("link2.txt"));
        fs::hard_link("file.txt", "link3.txt").unwrap();
        twd.cleanup_files.push(PathBuf::from("link3.txt"));
        twd.create_tmp_file("another.txt", 512 * 4);
        // link2 missing from the archive, throwing off deferrals
        let file_list: &str = "file.txt\nanother.txt\nlink1.txt\nlink3.txt\n";

        gnu_cpio_create(file_list.as_bytes(), "gnu.cpio");
        twd.cleanup_files.push(PathBuf::from("gnu.cpio"));

        let f = fs::File::create("dracut.cpio").unwrap();
        let mut writer = io::BufWriter::new(f);
        let mut reader = io::BufReader::new(file_list.as_bytes());
        let wrote = archive_loop(&mut reader, &mut writer, &ArchiveProperties::default()).unwrap();
        twd.cleanup_files.push(PathBuf::from("dracut.cpio"));
        assert!(wrote > NEWC_HDR_LEN * 5 + 512 * 8);

        let status = Command::new("diff")
            .args(&["gnu.cpio", "dracut.cpio"])
            .status()
            .expect("diff failed to start");
        assert!(status.success());
    }

    #[test]
    fn test_archive_hardlinks_multi() {
        let mut twd = TempWorkDir::new();
        twd.create_tmp_file("file.txt", 512 * 4);
        fs::hard_link("file.txt", "link1.txt").unwrap();
        twd.cleanup_files.push(PathBuf::from("link1.txt"));
        fs::hard_link("file.txt", "link2.txt").unwrap();
        twd.cleanup_files.push(PathBuf::from("link2.txt"));
        twd.create_tmp_file("another.txt", 512 * 4);
        fs::hard_link("another.txt", "anotherlink.txt").unwrap();
        twd.cleanup_files.push(PathBuf::from("anotherlink.txt"));
        // link2 missing from the archive, throwing off deferrals
        let file_list: &str = "file.txt\nanother.txt\nlink1.txt\nanotherlink.txt\n";

        gnu_cpio_create(file_list.as_bytes(), "gnu.cpio");
        twd.cleanup_files.push(PathBuf::from("gnu.cpio"));

        let f = fs::File::create("dracut.cpio").unwrap();
        let mut writer = io::BufWriter::new(f);
        let mut reader = io::BufReader::new(file_list.as_bytes());
        let wrote = archive_loop(&mut reader, &mut writer, &ArchiveProperties::default()).unwrap();
        twd.cleanup_files.push(PathBuf::from("dracut.cpio"));
        assert!(wrote > NEWC_HDR_LEN * 5 + 512 * 8);

        let status = Command::new("diff")
            .args(&["gnu.cpio", "dracut.cpio"])
            .status()
            .expect("diff failed to start");
        assert!(status.success());
    }

    #[test]
    fn test_archive_duplicates() {
        let mut twd = TempWorkDir::new();
        twd.create_tmp_file("file.txt", 512 * 4);
        twd.create_tmp_file("another.txt", 512 * 4);
        // file.txt is listed twice
        let file_list: &str = "file.txt\nanother.txt\nfile.txt\n";

        gnu_cpio_create(file_list.as_bytes(), "gnu.cpio");
        twd.cleanup_files.push(PathBuf::from("gnu.cpio"));

        let f = fs::File::create("dracut.cpio").unwrap();
        let mut writer = io::BufWriter::new(f);
        let mut reader = io::BufReader::new(file_list.as_bytes());
        let wrote = archive_loop(&mut reader, &mut writer, &ArchiveProperties::default()).unwrap();
        twd.cleanup_files.push(PathBuf::from("dracut.cpio"));
        assert!(wrote > NEWC_HDR_LEN * 4 + 512 * 12);

        let status = Command::new("diff")
            .args(&["gnu.cpio", "dracut.cpio"])
            .status()
            .expect("diff failed to start");
        assert!(status.success());
    }

    #[test]
    fn test_archive_hardlink_duplicates() {
        let mut twd = TempWorkDir::new();
        twd.create_tmp_file("file.txt", 512 * 4);
        fs::hard_link("file.txt", "ln1.txt").unwrap();
        twd.cleanup_files.push(PathBuf::from("ln1.txt"));
        fs::hard_link("file.txt", "ln2.txt").unwrap();
        twd.cleanup_files.push(PathBuf::from("ln2.txt"));
        twd.create_tmp_file("f2.txt", 512 * 4);
        // ln1 listed twice
        let file_list: &str = "file.txt\nf2.txt\nln1.txt\nln1.txt\nln1.txt\n";

        gnu_cpio_create(file_list.as_bytes(), "gnu.cpio");
        twd.cleanup_files.push(PathBuf::from("gnu.cpio"));

        let f = fs::File::create("dracut.cpio").unwrap();
        let mut writer = io::BufWriter::new(f);
        let mut reader = io::BufReader::new(file_list.as_bytes());
        let wrote = archive_loop(&mut reader, &mut writer, &ArchiveProperties::default()).unwrap();
        twd.cleanup_files.push(PathBuf::from("dracut.cpio"));
        assert!(wrote > NEWC_HDR_LEN * 4 + 512 * 8);

        let status = Command::new("diff")
            .args(&["gnu.cpio", "dracut.cpio"])
            .status()
            .expect("diff failed to start");
        assert!(status.success());
    }

    #[test]
    fn test_archive_list_separator() {
        let mut twd = TempWorkDir::new();
        twd.create_tmp_file("file1", 33);
        twd.create_tmp_file("file2", 55);
        let file_list_nulldelim: &str = "file1\0file2\0";

        let mut proc = Command::new("cpio")
            .args(&[
                "--quiet",
                "-o",
                "-H",
                "newc",
                "--reproducible",
                "-F",
                "gnu.cpio",
                "--null",
            ])
            .stdin(Stdio::piped())
            .spawn()
            .expect("GNU cpio failed to start");
        {
            let mut stdin = proc.stdin.take().unwrap();
            stdin
                .write_all(file_list_nulldelim.as_bytes())
                .expect("Failed to write to stdin");
        }

        let status = proc.wait().unwrap();
        assert!(status.success());
        twd.cleanup_files.push(PathBuf::from("gnu.cpio"));

        let f = fs::File::create("dracut.cpio").unwrap();
        let mut writer = io::BufWriter::new(f);
        let mut reader = io::BufReader::new(file_list_nulldelim.as_bytes());
        let wrote = archive_loop(
            &mut reader,
            &mut writer,
            &ArchiveProperties {
                list_separator: b'\0',
                ..ArchiveProperties::default()
            },
        )
        .unwrap();
        twd.cleanup_files.push(PathBuf::from("dracut.cpio"));
        assert!(wrote > NEWC_HDR_LEN * 3 + 33 + 55);

        let status = Command::new("diff")
            .args(&["gnu.cpio", "dracut.cpio"])
            .status()
            .expect("diff failed to start");
        assert!(status.success());
    }

    #[test]
    fn test_archive_fixed_mtime() {
        let mut twd = TempWorkDir::new();
        twd.create_tmp_file("file1", 33);
        twd.create_tmp_file("file2", 55);
        let file_list: &str = "file1\nfile2\n";

        twd.create_tmp_dir("extractor");
        let f = fs::File::create("extractor/dracut.cpio").unwrap();
        let mut writer = io::BufWriter::new(f);
        let mut reader = io::BufReader::new(file_list.as_bytes());
        let wrote = archive_loop(
            &mut reader,
            &mut writer,
            &ArchiveProperties {
                fixed_mtime: Some(0),
                ..ArchiveProperties::default()
            },
        )
        .unwrap();
        twd.cleanup_files
            .push(PathBuf::from("extractor/dracut.cpio"));
        assert!(wrote > NEWC_HDR_LEN * 3 + 33 + 55);

        let status = Command::new("cpio")
            .current_dir("extractor")
            .args(&[
                "--quiet",
                "-i",
                "--preserve-modification-time",
                "-H",
                "newc",
                "-F",
                "dracut.cpio",
            ])
            .status()
            .expect("GNU cpio failed to start");
        assert!(status.success());
        twd.cleanup_files.push(PathBuf::from("extractor/file1"));
        twd.cleanup_files.push(PathBuf::from("extractor/file2"));

        let md = fs::symlink_metadata("extractor/file1").unwrap();
        assert_eq!(md.mtime(), 0);
        let md = fs::symlink_metadata("extractor/file2").unwrap();
        assert_eq!(md.mtime(), 0);
    }

    #[test]
    fn test_archive_stat_mtime() {
        let mut twd = TempWorkDir::new();
        twd.create_tmp_file("file1", 33);
        twd.create_tmp_file("file2", 55);
        let file_list: &str = "file1\nfile2\n";

        twd.create_tmp_dir("extractor");
        let f = fs::File::create("extractor/dracut.cpio").unwrap();
        let mut writer = io::BufWriter::new(f);
        let mut reader = io::BufReader::new(file_list.as_bytes());
        assert_eq!(ArchiveProperties::default().fixed_mtime, None);
        let wrote = archive_loop(&mut reader, &mut writer, &ArchiveProperties::default()).unwrap();
        twd.cleanup_files
            .push(PathBuf::from("extractor/dracut.cpio"));
        assert!(wrote > NEWC_HDR_LEN * 3 + 33 + 55);

        let status = Command::new("cpio")
            .current_dir("extractor")
            .args(&[
                "--quiet",
                "-i",
                "--preserve-modification-time",
                "-H",
                "newc",
                "-F",
                "dracut.cpio",
            ])
            .status()
            .expect("GNU cpio failed to start");
        assert!(status.success());
        twd.cleanup_files.push(PathBuf::from("extractor/file1"));
        twd.cleanup_files.push(PathBuf::from("extractor/file2"));

        let src_md = fs::symlink_metadata("file1").unwrap();
        let ex_md = fs::symlink_metadata("extractor/file1").unwrap();
        assert_eq!(src_md.mtime(), ex_md.mtime());
        let src_md = fs::symlink_metadata("file2").unwrap();
        let ex_md = fs::symlink_metadata("extractor/file2").unwrap();
        assert_eq!(src_md.mtime(), ex_md.mtime());
    }

    #[test]
    fn test_archive_fixed_owner() {
        let mut twd = TempWorkDir::new();
        twd.create_tmp_file("file1", 33);
        twd.create_tmp_file("file2", 55);
        let file_list: &str = "file1\nfile2\n";

        let md = fs::symlink_metadata("file1").unwrap();
        // ideally we should check the process euid, but this will do...
        if md.uid() != 0 {
            println!("SKIPPED: this test requires root");
            return;
        }

        twd.create_tmp_dir("extractor");
        let f = fs::File::create("extractor/dracut.cpio").unwrap();
        let mut writer = io::BufWriter::new(f);
        let mut reader = io::BufReader::new(file_list.as_bytes());
        let wrote = archive_loop(
            &mut reader,
            &mut writer,
            &ArchiveProperties {
                fixed_uid: Some(65534),
                fixed_gid: Some(65534),
                ..ArchiveProperties::default()
            },
        )
        .unwrap();
        twd.cleanup_files
            .push(PathBuf::from("extractor/dracut.cpio"));
        assert!(wrote > NEWC_HDR_LEN * 3 + 33 + 55);

        let status = Command::new("cpio")
            .current_dir("extractor")
            .args(&["--quiet", "-i", "-H", "newc", "-F", "dracut.cpio"])
            .status()
            .expect("GNU cpio failed to start");
        assert!(status.success());
        twd.cleanup_files.push(PathBuf::from("extractor/file1"));
        twd.cleanup_files.push(PathBuf::from("extractor/file2"));

        let md = fs::symlink_metadata("extractor/file1").unwrap();
        assert_eq!(md.uid(), 65534);
        assert_eq!(md.gid(), 65534);
        let md = fs::symlink_metadata("extractor/file2").unwrap();
        assert_eq!(md.uid(), 65534);
        assert_eq!(md.gid(), 65534);
    }

    #[test]
    fn test_archive_stat_owner() {
        let mut twd = TempWorkDir::new();
        twd.create_tmp_file("file1", 33);
        twd.create_tmp_file("file2", 55);
        let file_list: &str = "file1\nfile2\n";

        twd.create_tmp_dir("extractor");
        let f = fs::File::create("extractor/dracut.cpio").unwrap();
        let mut writer = io::BufWriter::new(f);
        let mut reader = io::BufReader::new(file_list.as_bytes());
        assert_eq!(ArchiveProperties::default().fixed_uid, None);
        assert_eq!(ArchiveProperties::default().fixed_gid, None);
        let wrote = archive_loop(&mut reader, &mut writer, &ArchiveProperties::default()).unwrap();
        twd.cleanup_files
            .push(PathBuf::from("extractor/dracut.cpio"));
        assert!(wrote > NEWC_HDR_LEN * 3 + 33 + 55);

        let status = Command::new("cpio")
            .current_dir("extractor")
            .args(&["--quiet", "-i", "-H", "newc", "-F", "dracut.cpio"])
            .status()
            .expect("GNU cpio failed to start");
        assert!(status.success());
        twd.cleanup_files.push(PathBuf::from("extractor/file1"));
        twd.cleanup_files.push(PathBuf::from("extractor/file2"));

        let src_md = fs::symlink_metadata("file1").unwrap();
        let ex_md = fs::symlink_metadata("extractor/file1").unwrap();
        assert_eq!(src_md.uid(), ex_md.uid());
        assert_eq!(src_md.gid(), ex_md.gid());
        let src_md = fs::symlink_metadata("file2").unwrap();
        let ex_md = fs::symlink_metadata("extractor/file2").unwrap();
        assert_eq!(src_md.uid(), ex_md.uid());
        assert_eq!(src_md.gid(), ex_md.gid());
    }
}
