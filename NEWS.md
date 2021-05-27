[Rendered view](https://github.com/dracutdevs/dracut/blob/master/NEWS.md)

dracut-055
==========

#### Bug Fixes

* **base:**
    *  add missing `str_replace` to `dracut-dev-lib.sh` ([148e420b](https://github.com/dracutdevs/dracut/commit/148e420be5b5809aa8d5033f47477573bbbf3e60))
    *  split out `dracut-dev-lib.sh` ([c08bc810](https://github.com/dracutdevs/dracut/commit/c08bc8109d4c43beacfa4bcdc20a356102da6d02))
* **bash:**  minor cleanups ([9355cb8e](https://github.com/dracutdevs/dracut/commit/9355cb8ea5024533210067373657dc337d63ecb9))
* **dash:**  minor cleanups ([f4ea5f87](https://github.com/dracutdevs/dracut/commit/f4ea5f8734c4636f7d6db78da76e9525beb9a0ac))
* **dracut:**  pipe hardlink output to `dinfo` ([0a6007bf](https://github.com/dracutdevs/dracut/commit/0a6007bf4f472565d2c0c205a56edea7ba3e3bc3))
* **dracut-functions:**  get_maj_min without get_maj_min_cache_file set ([a277a5fc](https://github.com/dracutdevs/dracut/commit/a277a5fc7acc0a9e8d853f09671495f9d27645c1))
* **dracut-util:**  print error message with trailing newline ([b9b6f0ee](https://github.com/dracutdevs/dracut/commit/b9b6f0ee5b859a562e46a8c4e0dee0261fabf74d))
* **fs-lib:**  install fsck utilities ([12beeac7](https://github.com/dracutdevs/dracut/commit/12beeac741e4429146a674ef4ea9aa0bac10364b))
* **install:**
    *  configure logging earlier ([5eb24aa2](https://github.com/dracutdevs/dracut/commit/5eb24aa21d3ee639f869c2e363b3fb0b98be552b))
    *  sane default --kerneldir ([c1ab3613](https://github.com/dracutdevs/dracut/commit/c1ab36139d416e580e768c29f2addf7ccbc2c612), closes [#1505](https://github.com/dracutdevs/dracut/issues/1505))
* **integrity:**  require ALLOW_METADATA_WRITES to come from EVM config file ([b12d91c4](https://github.com/dracutdevs/dracut/commit/b12d91c431220488fecf7b4be82427e3560560cb))
* **mksh:**  minor cleanups ([6c673298](https://github.com/dracutdevs/dracut/commit/6c673298f36990665467564e6114c9ca2530f584))
* **squash:**  don't mount the mount points if already mounted ([636d6df3](https://github.com/dracutdevs/dracut/commit/636d6df3134dde1dac72241937724bc59deb9303))
* **warpclock:**  minor cleanups ([7d205598](https://github.com/dracutdevs/dracut/commit/7d205598c6a500b58b4d328e824d0446276f7ced))

#### Features

* **dracut.sh:**  detect running in a container ([7275c6f6](https://github.com/dracutdevs/dracut/commit/7275c6f6a0f6808cd939ea5bdf1244c7bd13ba44))
* **install:**  add default value for --firmwaredirs ([4cb086fa](https://github.com/dracutdevs/dracut/commit/4cb086fa2995799b95c0b25bc9a0cf72ba3868ea))

#### Contributors

- Harald Hoyer <harald@redhat.com>
- Jóhann B. Guðmundsson <johannbg@gmail.com>
- Marcos Mello <marcosfrm@gmail.com>
- Kairui Song <kasong@redhat.com>
- Lars Wendler <polynomial-c@gentoo.org>
- Stefan Berger <stefanb@linux.ibm.com>
- Tomasz Paweł Gajc <tpgxyz@gmail.com>

dracut-054
==========

With this release dracut has undergone a major overhaul.

A lot of systemd related modules have been added.

The integration test suite has finally ironed out the flaky behaviour due to the parallel device probing of the kernel,
which bit sometimes in the non-kvm github CI. So, if you see any `/dev/sda` in a setup script with more than two hard drives,
chances are, that the script works on the wrong disk. Same goes for network interfaces.

This release is also fully `shellcheck`'ed with `ShellCheck-0.7.2` and indented with `shfmt` and `astyle`.

The dracut project builds test containers every day for:
* `opensuse/tumbleweed-dnf:latest`
* `archlinux:latest`
* `fedora:rawhide`
* `fedora:latest`
* `fedora:33`

These containers can easily be used to run the integration tests locally without root permissions via `podman`.
We hope this serves as a blueprint for your distribution's CI process.

More information can be found in [docs/HACKING.md](https://github.com/dracutdevs/dracut/blob/master/HACKING.md).

#### Bug Fixes

*   make testsuite pass on OpenSuse and Arch ([8b2afb08](https://github.com/dracutdevs/dracut/commit/8b2afb08baea7fc6e15ece94e287dcc4a008bcc4))
*   cope with distributions with `/usr/etc` files ([3ad3b3a4](https://github.com/dracutdevs/dracut/commit/3ad3b3a40d419c4386b2924f6ac25ab0c355d131))
*   deprecate gummiboot ([5c94cf41](https://github.com/dracutdevs/dracut/commit/5c94cf41e8937b6fbb72c96bc54c84fdf224c711))
*   set vimrc and emacs indention according to .editorconfig ([9012f399](https://github.com/dracutdevs/dracut/commit/9012f3996b1e5f0788f8e80dfdd5c9ab0636c355))
*   correctly handle kernel parameters ([501d82f7](https://github.com/dracutdevs/dracut/commit/501d82f79675a6bf9b37e8250152515863a80236))
*   remove dracut.pc on `make clean` ([d643156d](https://github.com/dracutdevs/dracut/commit/d643156d561d3aca816d75e403149db073617292))
*   honor KVERSION environment in the Makefile ([d8a454a5](https://github.com/dracutdevs/dracut/commit/d8a454a537c6de95033dec7d83c622fdc46c2a4f))
*   always use mkdir -p ([9cf7b1c5](https://github.com/dracutdevs/dracut/commit/9cf7b1c529442d5abd6eaec4399d4ee77b95145e))
* **dracut.sh:**
    *  prevent symbolic links containing `//` ([de0c0872](https://github.com/dracutdevs/dracut/commit/de0c0872fc858fa9ca952f79ea9f00be17c37a4c))
    *  adding missing globalvars for udev ([f35d479d](https://github.com/dracutdevs/dracut/commit/f35d479d2b718da54886a66d3b7af2132215f80a))
    *  sysctl global variables ([3ca9aa1d](https://github.com/dracutdevs/dracut/commit/3ca9aa1d7b24b82e01d16613b86ec3be97c8a1bb))
    *  add global vars for modules-load ([ec4539c6](https://github.com/dracutdevs/dracut/commit/ec4539c6066edf25e52ed8e2d35c4be7ef39f729))
    *  omission is an addition to other omissions in conf files ([96c31333](https://github.com/dracutdevs/dracut/commit/96c313333d1a4f5e2c524a3a11c5b3aab24afc20))
    *  harden dracut against GZIP environment variable ([d8e47e20](https://github.com/dracutdevs/dracut/commit/d8e47e201af4646e2a82e11220ea9c993bd2ed48))
    *   add a missing tmpfilesconfdir global variable ([8849dd8d](https://github.com/dracutdevs/dracut/commit/8849dd8d1a74a46cb761c4d8041e4582d4686724))
    *   include `modules.builtin.alias` in the initramfs ([7f633747](https://github.com/dracutdevs/dracut/commit/7f6337471312486934f9592c1c7c05ed68694454))
    *   install all depmod relevant configuration files ([50a01dd4](https://github.com/dracutdevs/dracut/commit/50a01dd4b28471c0dfa810a705e219963bd5ec3c))
    *   add `modules.builtin.modinfo` to the initramfs ([87c4c178](https://github.com/dracutdevs/dracut/commit/87c4c17850e8bb982f6c07a6d3f58124bb2875de))
    *   search for btrfs devices from actual mount poiont ([3fdc734a](https://github.com/dracutdevs/dracut/commit/3fdc734a5cc8c0b94c1da49439181d540c8a5c43))
* **dracut-functions.sh:**
    *  implement a cache for get_maj_min ([c3bb9d18](https://github.com/dracutdevs/dracut/commit/c3bb9d18dceed7db6d16f9c2a7f682c5934099d7))
    *  word splitting issue for sed in get_ucode_file ([122657b2](https://github.com/dracutdevs/dracut/commit/122657b2fedf13991597830cca4d4ddbc8038233))
* **dracut-logger.sh:**  double dash trigger unknown logger warnings during run ([4fbccde5](https://github.com/dracutdevs/dracut/commit/4fbccde50456f513d388cdfd858018cd889890dc))
* **dracut-install:**
    *  handle $LIB in ldd output parsing ([d1a36d3d](https://github.com/dracutdevs/dracut/commit/d1a36d3d80b0ed71ee814659e18a020c53cee05e))
    *  handle builtin modules ([2536a9ea](https://github.com/dracutdevs/dracut/commit/2536a9eaffbc9cc14c85579a2f537d3f3a1d5659))
* **base:**
    *  suppress calls to getarg in build phase ([6feaaabc](https://github.com/dracutdevs/dracut/commit/6feaaabc221ffbf79f652cbee3eea58f02449c50))
    *  source hooks without exec ([8059bcb2](https://github.com/dracutdevs/dracut/commit/8059bcb2c8df4d60cc2f548d3c53db25d815a7be))
    *  wait_for_dev quote shell variables ([b800edd6](https://github.com/dracutdevs/dracut/commit/b800edd69817b5e46d5f240b96d3b3648267ea21))
    *  adding crc32c for ext3 ([61f45643](https://github.com/dracutdevs/dracut/commit/61f456435879f084a1bf2c8885eaf37070035abf))
* **crypt:**
    *  install all crypto modules in the generic initrd ([10f9e569](https://github.com/dracutdevs/dracut/commit/10f9e569c52654ff54678a626a0f5dd14233716d))
    *  include cryptsetups tmpfile ([a4cc1964](https://github.com/dracutdevs/dracut/commit/a4cc196467e45f093fab7876c1c6b40798058920))
* **crypt-gpg:**
    *  cope with different scdaemon location ([44fd1c13](https://github.com/dracutdevs/dracut/commit/44fd1c13555f2e12bb566c246948629ada27d14d))
* **dbus-broker:**
    *  enable the service ([df1e5f06](https://github.com/dracutdevs/dracut/commit/df1e5f06a5449dcec6749baf742eac6eb1f0aa53))
* **dbus-daemon:**
    *  only error out in install() ([ae4fbb3d](https://github.com/dracutdevs/dracut/commit/ae4fbb3db4136e6e03a1c74d05ecc2a73b916401))
* **dracut-systemd:**
    *  don't refuse root=tmpfs when systemd is used ([a96900a8](https://github.com/dracutdevs/dracut/commit/a96900a82c3a8ec1ed2c6b2cc8862f912093fa0c))
* **examples:**  remove the examples directory and reference to it ([b37c90c8](https://github.com/dracutdevs/dracut/commit/b37c90c8e00155a1f31237ae6cf91a81677c4df5))
* **fips:**
    *  add dh and ecdh ciphers ([543b8014](https://github.com/dracutdevs/dracut/commit/543b8014fc10fc6a92ba83db0dfc994fc1d2129b))
    *  remove old udev version requirements ([be30d987](https://github.com/dracutdevs/dracut/commit/be30d98751cff4ace660215305e2468943a45754))
* **i18n:**
    *  skip if data is missing ([651fe01e](https://github.com/dracutdevs/dracut/commit/651fe01e7937d86bbd471d9621581bed44f23dfa))
* **img-lib:**
    *  ignored null byte in input ([85eb9680](https://github.com/dracutdevs/dracut/commit/85eb96802cb82ec179bd3bc429b0dad2518946c5))
* **integrity:**
    *  properly set up EVM when using an x509 cert ([4bdd7eb2](https://github.com/dracutdevs/dracut/commit/4bdd7eb23a8187c3f19797e47eee8c672cea33ae))
* **iscsi:**
    *  replace sed call with bash internals ([66b920c6](https://github.com/dracutdevs/dracut/commit/66b920c65143f4cac80385a51704ae9483305569))
    *  add iscsid.service requirements ([bb6770f1](https://github.com/dracutdevs/dracut/commit/bb6770f1a413bdc7fd570b260ee28ace1255a195))
    *  only rely on socket activiation ([0eb87d78](https://github.com/dracutdevs/dracut/commit/0eb87d78108aae9aa4692f1edfb33ded50e26409))
* **kernel-modules:**
    *  optionally add /usr/lib/modules.d to initramfs ([92e6a8f8](https://github.com/dracutdevs/dracut/commit/92e6a8f87914322994387e559cf2a00b1760b301))
    *  add watchdog drivers for generic initrd ([3a60c036](https://github.com/dracutdevs/dracut/commit/3a60c036db7caccda95475d33c8d4ce1f615d2c8))
* **mdraid:**
    *  remove dependency statements ([86b75634](https://github.com/dracutdevs/dracut/commit/86b756346a6b7c5cb5f6fda4d12e2a58b6144e40))
* **memstrack:**
    *  correct dependencies ([c2ecc4d1](https://github.com/dracutdevs/dracut/commit/c2ecc4d131876383b47820a2e8d1a6f8a11716d9))
* **multipath:**
    *  stop multipath before udev db cleanup ([3c244c7c](https://github.com/dracutdevs/dracut/commit/3c244c7ca3555b526883dc20104c469b39085cbe))
    *  revise multipathd-stop ([7b8c78ff](https://github.com/dracutdevs/dracut/commit/7b8c78ff43a1f8e3690969e980d3d9d1dcb00c87))
* **nbd:**
    *  assume nbd version >= 3.8 ([6209edeb](https://github.com/dracutdevs/dracut/commit/6209edeb5c7783d94867829bf052aa53c78a1efe))
    *  remove old udev version requirements ([fd15dbad](https://github.com/dracutdevs/dracut/commit/fd15dbad6ebad86a3753a03f98706010f3e36cf7))
    *  make nbd work again with systemd ([77906443](https://github.com/dracutdevs/dracut/commit/7790644362622097aa69107920fd26b688c855d3))
* **network:**
    *  use wicked unit instead of find_binary ([57eefcf7](https://github.com/dracutdevs/dracut/commit/57eefcf70587f06b8874a3b3cf31e9ab70c03227))
    *  user variable for sdnetworkd instead of path ([4982e16d](https://github.com/dracutdevs/dracut/commit/4982e16dd53dcbbcfbd3a6b59013a0d6f893f840))
    *  correct regression in iface_has_carrier ([36af0518](https://github.com/dracutdevs/dracut/commit/36af0518b3fe59442de206c24bbe03be6fc17095))
* **network-legacy:**
    *  add missing options to dhclient.conf ([abfd547a](https://github.com/dracutdevs/dracut/commit/abfd547a85230a4520df65280aaf195f319df464))
    *  silence getargs ([60a34d8b](https://github.com/dracutdevs/dracut/commit/60a34d8b11dd50b2cd4e0e2208bd7c5e0fc48b71))
* **network-manager:**
    *  cope with distributions not using `libexec` ([22d6863e](https://github.com/dracutdevs/dracut/commit/22d6863ef1b2eb2a22264f2bfdb2b9329ab5dfdb))
    *  set timeout via command line option ([8a51ee1f](https://github.com/dracutdevs/dracut/commit/8a51ee1fa61bd3da342be53e35730837afd2caad))
    *  run after dracut-cmdline ([4d03404f](https://github.com/dracutdevs/dracut/commit/4d03404f499064b354a58223895cc47dbb461da5))
    *  create /run directories ([49b61496](https://github.com/dracutdevs/dracut/commit/49b614961dc8684f8512febbf80da489909e4b7f))
    *  use /run/NetworkManager/initrd/neednet in initqueue ([6a37c6f6](https://github.com/dracutdevs/dracut/commit/6a37c6f6302f950df608db3fd45acf9342ee3de2))
    *  only run NetworkManager if rd.neednet=1 ([ac0e8f7d](https://github.com/dracutdevs/dracut/commit/ac0e8f7dcc81432311906c3fca0d4211f6a2f68c))
    *  nm-run.service: don't kill forked processes ([1f21fac6](https://github.com/dracutdevs/dracut/commit/1f21fac646daa46cbe184ef8ff7705842f06ba15))
    *  no default deps for nm-run.service ([ba4bcf5f](https://github.com/dracutdevs/dracut/commit/ba4bcf5f4f11ad624c647ddf4f566997186135e7))
    *  nm-lib.sh does not require bash ([3402142e](https://github.com/dracutdevs/dracut/commit/3402142e344298c8f20fc52a2b064344788f1668))
* **squash:**
    *  post install should be the last step before stripping ([8c8aecdc](https://github.com/dracutdevs/dracut/commit/8c8aecdc63c9389038e78ee712d4809e49add5e1))
* **systemd:**
    *  include all nss libraries ([b3bbf5fb](https://github.com/dracutdevs/dracut/commit/b3bbf5fb6a95cfb69272da0711b5c5e0c6621de9))
    *  include hosts and nsswitch.conf in hostonly mode ([5912f4fb](https://github.com/dracutdevs/dracut/commit/5912f4fbc036cc36b9507c16dddef1ded1556572))
    *  remove old systemd version requirements ([fc53987b](https://github.com/dracutdevs/dracut/commit/fc53987bec1bc71b054d99072f62c1770a44bcca))
* **systemd-hostnamed:**  extra quote ([2aa65234](https://github.com/dracutdevs/dracut/commit/2aa652349ca83198581cccb516a241a8d0e1b4d9))
* **systemd-modules:**  remove dependency on systemd meta module ([afef4557](https://github.com/dracutdevs/dracut/commit/afef455718db69cff3797ca1a6d8bfebd2e86ab3))
* **systemd-modules-load:**
    *  misc repairs ([782ac8f1](https://github.com/dracutdevs/dracut/commit/782ac8f1f6b68edfe59630e9e4ac1673636f3a5e))
* **systemd-networkd:**
    *  make systemd-networkd a proper network provider ([ea779750](https://github.com/dracutdevs/dracut/commit/ea779750c371102c04252b48f1b7d9c7ece7cf93), closes [#737](https://github.com/dracutdevs/dracut/issues/737))
* **systemd-resolved:**  remove nss libraries ([12bef83c](https://github.com/dracutdevs/dracut/commit/12bef83cdaf329e3ee2cc1f282bd9c128ec0fc56))
* **systemd-sysctl:**
    *  sysctl global variables ([02acedd0](https://github.com/dracutdevs/dracut/commit/02acedd09eb7222eaaf0f5256f3ddec26d658360))
* **systemd-sysusers:**
    *  misc fixes and cleanup ([7359ba8a](https://github.com/dracutdevs/dracut/commit/7359ba8acab2652cfff6b845f84a936cdec30f9d))
* **systemd-udev:**  use global vars instead of fixed path ([fd883a58](https://github.com/dracutdevs/dracut/commit/fd883a58d1360f0c6c32f64462fafdd7a54af1ee))
* **systemd-udevd:**  add udev id program files ([562cb77b](https://github.com/dracutdevs/dracut/commit/562cb77b5a28e3f31bc6d327c7712fba661e9a27))
* **systemd-verity:**
    *  incorrect reference to cryptsetup target ([ba92d1fc](https://github.com/dracutdevs/dracut/commit/ba92d1fcad68758004d7b1102fe1905c0f25e63e))
    *  re-naming module to veritysetup ([0267f3c3](https://github.com/dracutdevs/dracut/commit/0267f3c3554efd8f027afaf462347167402f5d6c))
* **tpm2-tss:**  add tpm2 requirement ([8f99fada](https://github.com/dracutdevs/dracut/commit/8f99fadabea8f279a9fe28473dba424eb38f8d60))
* **udev-rules:**
    *  remove sourcing of network link files ([69f4e7cd](https://github.com/dracutdevs/dracut/commit/69f4e7cdc3f7da24e40496b0b2f0f5022cc3376d))
    *  add btrfs udev rules by default ([567c4557](https://github.com/dracutdevs/dracut/commit/567c4557537fe7f477f0f54237df00ebc79e56be))
* **url-lib:**
    *  fix passing args ([5f6be515](https://github.com/dracutdevs/dracut/commit/5f6be51595eab878314d031d9bfebe844b639302))
* **zipl:**
    *  don't depend on grub2 ([6b499ec1](https://github.com/dracutdevs/dracut/commit/6b499ec14b3ff35d5298617b436b64563a2d8c2f))

#### Performance

*   disable initrd compression when squash module is enabled ([7c0bc0b2](https://github.com/dracutdevs/dracut/commit/7c0bc0b2fd167da42035020dae49af94844f053c))

#### Features

*   support ZSTD-compressed kernel modules ([ce9af251](https://github.com/dracutdevs/dracut/commit/ce9af251af5fca08ea206ef980005853a4dac36e))
*   also restore the initramfs from /lib/modules ([33e27fab](https://github.com/dracutdevs/dracut/commit/33e27fab59db60b1ca05a0c5b8a51fccb98578e5))
*   extend Makefile indent target ([e0a0fa61](https://github.com/dracutdevs/dracut/commit/e0a0fa61749152fd5bc837770a02cf22d7e02d40))
*   customize .editorconfig according to shfmt ([1f621aba](https://github.com/dracutdevs/dracut/commit/1f621aba3728a621b83b3b697eae6caadae9d287))
*   squash module follow --compress option ([5d05ffbd](https://github.com/dracutdevs/dracut/commit/5d05ffbd87bc27e27f517ebc3454d50729c687e6))
* **bluetooth:**  implement bluetooth support in initrd ([64ee2a53](https://github.com/dracutdevs/dracut/commit/64ee2a53864576fbedabe6b18fb9aae01b999199))
* **btrfs:**  add 64-btrfs-dm.rules rules ([d4caa86a](https://github.com/dracutdevs/dracut/commit/d4caa86aba35b51dc1adda3ee3a5bae677420082))
* **mkinitrd:**  remove mkinitrd ([43df4ee2](https://github.com/dracutdevs/dracut/commit/43df4ee274e7135aff87868bf3bf2fbab47aa8b4))
* **nbd:**  support ipv6 link local nbds ([b12f8188](https://github.com/dracutdevs/dracut/commit/b12f8188a4ffac312694ebd48a5c99ba885e6467))
* **network-manager:**  run as daemon with D-Bus ([112f03f9](https://github.com/dracutdevs/dracut/commit/112f03f9e225a790cbc6378c70773c6af5e7ee34))
* **qemu:**  include the virtio_mem kernel module ([f3dcb606](https://github.com/dracutdevs/dracut/commit/f3dcb60619671f2d353caaa42d38207172c8b3ba))
* **skipcpio:**  speed up and harden skipcpio ([63033495](https://github.com/dracutdevs/dracut/commit/630334950c9a7a714fdf31b6ff545d804b5df2f2))
* **squash:**
    *  use busybox for early setup if available ([90f269f6](https://github.com/dracutdevs/dracut/commit/90f269f6afe409925bad86f0bd7e9322ad9b4fb0))
    *  install and depmod modules seperately ([5a18b24a](https://github.com/dracutdevs/dracut/commit/5a18b24a8b9c20c98f711963ce5407ceb2f3d57b))
* **systemd-ac-power:**  introducing the systemd-ac-power module ([e7407230](https://github.com/dracutdevs/dracut/commit/e74072306958262f22a9ecf10b928647ebdacf8f))
* **systemd-hostnamed:**  introducing the systemd-hostnamed module ([bf273e3e](https://github.com/dracutdevs/dracut/commit/bf273e3e8632faff68fe19f9d7d7cc42e5a7c480))
* **systemd-initrd:**  add initrd-usr-fs.target ([5eb73610](https://github.com/dracutdevs/dracut/commit/5eb736103d06197f37283bc27815c050adec81ea))
* **systemd-journald:**  introducing the systemd-journald module ([3697891b](https://github.com/dracutdevs/dracut/commit/3697891b754493ecd6b19dbf279701bad3460fcd))
* **systemd-ldconfig:**  introducing the systemd-ldconfig module ([563c434e](https://github.com/dracutdevs/dracut/commit/563c434ecba68c628344c1a684f656cdd8f9f214))
* **systemd-network-management:**  introducing systemd-network-management module ([e942d86c](https://github.com/dracutdevs/dracut/commit/e942d86c9ddad19f9307d58cb2d99169f6e94edb))
* **systemd-resolved:**  introducing the systemd-resolved module ([b7d3caef](https://github.com/dracutdevs/dracut/commit/b7d3caef6780305c553851169ca30b0b05b6ff31))
* **systemd-rfkill:**  introducing the systemd-rfkill module ([21536544](https://github.com/dracutdevs/dracut/commit/215365441e1042793d62c4c9e146be5916ed5aeb))
* **systemd-sysext:**  introducing the systemd-sysext module ([fc88af54](https://github.com/dracutdevs/dracut/commit/fc88af54134ec021be58465b52d1271453c30c55))
* **systemd-timedated:**  introducing the systemd-timedated module ([1c41cc90](https://github.com/dracutdevs/dracut/commit/1c41cc90c52636e03abdf6d0c4fa0f557b7eb449))
* **systemd-timesyncd:**  introducing the systemd-timesyncd module ([2257d545](https://github.com/dracutdevs/dracut/commit/2257d54583d24ca69d10b5e600b986d412a21714))
* **systemd-tmpfiles:**  introducing the systemd-tmpfiles module ([2b61be32](https://github.com/dracutdevs/dracut/commit/2b61be32b890e70b1fce45d984327c27302da9bc))
* **systemd-udevd:**  introducing the systemd-udevd module ([3534789c](https://github.com/dracutdevs/dracut/commit/3534789cc42331bc22cf44d26a1d04db4e010ad9))
* **systemd-verity:**  introducing the systemd-verity module ([3d4dea58](https://github.com/dracutdevs/dracut/commit/3d4dea58f9821e58841d5c738b9935193c680181))
* **tpm2-tss:**  introducing the tpm2-tss module ([8743b073](https://github.com/dracutdevs/dracut/commit/8743b0735692ab3f333815ba311cecdc29d45ecd))

#### Contributors

- Harald Hoyer <harald@redhat.com>
- Jóhann B. Guðmundsson <johannbg@gmail.com>
- Kairui Song <kasong@redhat.com>
- Dusty Mabe <dusty@dustymabe.com>
- Beniamino Galvani <bgalvani@redhat.com>
- Mikhail Novosyolov <m.novosyolov@rosalinux.ru>
- Renaud Métrich <rmetrich@redhat.com>
- Adam Alves <adamoa@gmail.com>
- Daniel Molkentin <daniel.molkentin@suse.com>
- David Hildenbrand <david@redhat.com>
- David Tardon <dtardon@redhat.com>
- Jaroslav Jindrak <dzejrou@gmail.com>
- Jonas Jelten <jj@sft.lol>
- Lennart Poettering <lennart@poettering.net>
- Lev Veyde <lveyde@redhat.com>
- Peter Robinson <pbrobinson@fedoraproject.org>
- Stefan Berger <stefanb@linux.ibm.com>
- Đoàn Trần Công Danh <congdanhqx@gmail.com>

dracut-053
==========

#### Bug Fixes

* **dracut.sh:**
  *  unfreeze /boot on exit ([d87ae137](https://github.com/dracutdevs/dracut/commit/d87ae13721d04a8a2192d896af224ac6965caf70))
  *  proper return code for inst_multiple in dracut-init.sh ([d437970c](https://github.com/dracutdevs/dracut/commit/d437970c013e3287de263a1e60a117b15239896c))
* **fcoe:**
  *  rename rd.nofcoe to rd.fcoe ([6f7823bc](https://github.com/dracutdevs/dracut/commit/6f7823bce65dd4b52497dbb94892b637fd06471a))
  *  rd.nofcoe=0 should disable fcoe ([805b46c2](https://github.com/dracutdevs/dracut/commit/805b46c2a81e04d69fc3af912942568516d05ee7))
* **i18n:**
  *  get rid of `eval` calls ([5387ed24](https://github.com/dracutdevs/dracut/commit/5387ed24c8b33da1214232d57ab1831e117aaba0))
  *  create the keyboard symlinks again ([9e1c7f3d](https://github.com/dracutdevs/dracut/commit/9e1c7f3deadd387adaa97b189593b4ba3d7c6d5a))
* **network-manager:**
  *  run as a service if systemd module is present ([c17c5b76](https://github.com/dracutdevs/dracut/commit/c17c5b7604c8d61dd1c00ee22d44c3a5d7d6dfee))
  *  rework how NM is started in debug mode ([34c73b33](https://github.com/dracutdevs/dracut/commit/34c73b339baa025dfd8916379c4d191be34a8af5))
* **drm:**  skip empty modalias files in drm module setup ([c3f24184](https://github.com/dracutdevs/dracut/commit/c3f241849de6434d063ef92e6880f6b0335c1800))


dracut-052
==========

#### Features

- **dracut:**
  - allow overriding the systemctl command for sysroot with `$SYSTEMCTL` for cross compilation
  - add additional global variables

     Variables like `dbusconfdir` or `systemdnetwork` are now exported
     to the individual modules as global variables. If they are not set
     in the distribution dracut config files, they are set via `pkg-config`

  - A `--no-uefi` option as been added to the CLI options to disable a default `uefi=yes`
    set by a configuration file.

- **kernel-modules:**  add modules from `drivers/memory` for arm
- **network-legacy:**  send dhcp in parallel on all devices via the `single-dhcp` option
- **dbus:**  introduce a meta module for dbus
- **dbus-broker:**  introduce the dbus-broker module
- **dbus-daemon:**  introduce the dbus-daemon module
- **systemd-ask-password:**  introduce the systemd-ask-password module
- **systemd-coredump:**  introduce the systemd-coredump module
- **systemd-modules-load:**  introduce the systemd-modules-load module
- **systemd-repart:**  introduce the systemd-repart module
- **systemd-sysctl:**  introduce the systemd-sysctl module
- **systemd-sysusers:** introduce the systemd-sysuser module

#### Bug Fixes

-   first round of shellcheck for all shell scripts
-   revise all module checks to not error out about missing dependencies
-   use the top-level `/efi` path to address the EFI partition
-   correct the squash quirk
-   use `find_binary` instead of other methods, because `find_binary` honors `dracutsysrootdir`
-   quote globbing in module-setup.sh for `inst_multiple`
-   move ldconfig after library workaround
-   do not set cmdline for uefi images unless asked
- **dracut:**  don't override `PATH`, if `dracutsysrootdir` is set
- **dracut-functions.sh:**  check kernel config from `dracutsysrootdir`
- **dracut-init.sh:**  make inst_libdir_file work with `dracutsysrootdir` set
- **dracut-install:**  allow globbing for multiple sources
- **06dbus:**
  -  do not hardcode path to dbus utils
  -  do not hardcode path to systemd unit
- **uefi**  use efivars fs over the deprecated sysfs entries
- **keyring**  adding shared keyring mode to systemd unit `dracut-pre-pivot.service`
- **35network-manager:**  avoid restarting NetworkManager
- **90kernel-modules:**  install generic crypto modules with hostonly unset
- **99squash:**  use kernel config instead of modprobe to check modules
- **dbus-daemon:**  use uid/gid from sysroot if `dracutsysrootdir` is set
- **kernel-modules:**  add reset controllers for arm
- **kernel-network-modules:**  also install modules from mdio subdirectory
- **mdraid:**
  -  remove the `offroot` option (long deprecated)
  -  add the grow continue service `mdadm-grow-continue`
- **network-legacy:**  silent the check for dhcp leaseinfo
- **network-manager:**  allow override network manager version
- **plymouth:**  install binaries with dependencies
- **shutdown:**  add timeout to umount calls
- **watchdog:**  fix dependencies in `module-setup.sh`

#### Contributors

- Harald Hoyer <harald@redhat.com>
- Jóhann B. Guðmundsson <johannbg@gmail.com>
- Zoltán Böszörményi <zboszor@pr.hu>
- Alexey Shabalin <shaba@altlinux.org>
- Daniel Molkentin <daniel.molkentin@suse.com>
- Luiz Angelo Daros de Luca <luizluca@gmail.com>
- Mariusz Tkaczyk <mariusz.tkaczyk@linux.intel.com>
- Alexander Tsoy <alexander@tsoy.me>
- Anjali Kulkarni <anjali.k.kulkarni@oracle.com>
- Beniamino Galvani <bgalvani@redhat.com>
- David Tardon <dtardon@redhat.com>
- Javier Martinez Canillas <javierm@redhat.com>
- Kairui Song <kasong@redhat.com>
- Lukas Nykryn <lnykryn@redhat.com>
- Matthew Thode <mthode@mthode.org>
- Nicolas Chauvet <kwizart@gmail.com>
- Nicolas Saenz Julienne <nsaenzjulienne@suse.de>
- Ondrej Mosnacek <omosnace@redhat.com>
- Peter Levine <plevine457@gmail.com>
- Petr Pavlu <petr.pavlu@suse.com>
- Vladius25 <vkorol2509@icloud.com>
- Yang Liu <50459973+ly4096x@users.noreply.github.com>
- foopub <45460217+foopub@users.noreply.github.com>
- realtime-neil <neil@rtr.ai>


dracut-051
==========

dracut:
- allow running on a cross-compiled rootfs

  dracutsysrootdir is the root directory, file existence checks use it.

  DRACUT_LDCONFIG can override ldconfig with a different one that works
  on the sysroot with foreign binaries.

  DRACUT_LDD can override ldd with a different one that works
  with foreign binaries.

  DRACUT_TESTBIN can override /bin/sh. A cross-compiled sysroot
  may use symlinks that are valid only when running on the target
  so a real file must be provided that exist in the sysroot.

  DRACUT_INSTALL now supports debugging dracut-install in itself
  when run by dracut but without debugging the dracut scripts.
  E.g. DRACUT_INSTALL="valgrind dracut-install or
  DRACUT_INSTALL="dracut-install --debug".

  DRACUT_COMPRESS_BZIP2, DRACUT_COMPRESS_LBZIP2, DRACUT_COMPRESS_LZMA,
  DRACUT_COMPRESS_XZ, DRACUT_COMPRESS_GZIP, DRACUT_COMPRESS_PIGZ,
  DRACUT_COMPRESS_LZOP, DRACUT_COMPRESS_ZSTD, DRACUT_COMPRESS_LZ4,
  DRACUT_COMPRESS_CAT: All of the compression utilities may be
  overridden, to support the native binaries in non-standard places.

  DRACUT_ARCH overrides "uname -m".

  SYSTEMD_VERSION overrides "systemd --version".

  The dracut-install utility was overhauled to support sysroot via
  a new option -r and fixes for clang-analyze. It supports
  cross-compiler-ldd from
  https://gist.github.com/jerome-pouiller/c403786c1394f53f44a3b61214489e6f

  DRACUT_INSTALL_PATH was introduced so dracut-install can work with
  a different PATH. In a cross-compiled environment (e.g. Yocto), PATH
  points to natively built binaries that are not in the host's /bin,
  /usr/bin, etc. dracut-install still needs plain /bin and /usr/bin
  that are relative to the cross-compiled sysroot.

  DRACUT_INSTALL_LOG_TARGET and DRACUT_INSTALL_LOG_LEVEL were
  introduced so dracut-install can use different settings from
  DRACUT_LOG_TARGET and DRACUT_LOG_LEVEL.

- don't call fsfreeze on subvol of root file system
- Use TMPDIR (typically /run/user/$UID) if available
- dracut.sh: add check for invalid configuration files
  Emit a warning about possible misconfigured configuration files, where
  the spaces around values are missing for +=""
- dracut-functions: fix find_binary() to return full path
- dracut.sh: FIPS workaround for openssl-libs on Fedora/RHEL
- dracut.sh: fix early microcode detection logic
- dracut.sh: fix ia32 detection for uefi executables
- dracut.sh: Add --version
- dracut.sh: Add --hostonly-nics option
- EFI Mode: only write kernel cmdline to UEFI binary
- Allow $DRACUT_INSTALL to be not an absolute path
- Don't print when a module is explicitly omitted (by default)
- Remove uses of bash (and bash specific syntax) in runtime scripts
- dracut-init.sh: Add a helper for detect device kernel modules
- dracut-functions.sh: Fix check_block_and_slaves_all
- dracut-functions.sh: add a helper to check if kernel module is available

Documentation
- dracut.cmdline.7.asc: clarify usage of `rd.lvm.vg` and `rd.lvm.lv`
- dracut.conf.5.asc: document how to config --no-compress in the config
- fix CI badges in README.md and fix dracut description
- dracut.modules.7.asc: fix typos
- dracut.modules.7.asc: fix reference to insmodpost module
- Add --version to man page
- Adding code of conduct
- Document initqueue/online hook


dracut-install:
- install: also install post weak dependencies of kernel modules
- install: Globbing support for resolving "firmware:"

mkinitrd:
- use vmlinux regex for ppc*, vmlinuz for i686

mkinitrd-suse:
- fix i586 platform detection

modules:

00systemd:
- skip dependency add for non-existent units
- add missing cryptsetup-related targets

05busybox:
- simplify listing of supported utilities

06rngd:
- install dependant libs too
- Do not start inside container

10i18n:
- i18n: Always install /etc/vconsole.conf

35network-legacy:
- dhclient-script: Fix typo in output of  BOUND & BOUND6 cases
- simplify fallback dhcp setup

35network-manager:
- ensure that nm-run.sh is executed when needed
- install libnss DNS and mDNS plugins
- always pull in machinery to read ifcfg files
- set kernel hostname from the command line
- move connection generation to a lib file

40network:
- fix glob matching ipv6 addresses
- net-lib.sh: support infiniband network mac addresses

45url-lib:
- drop NSS if it's not in curl --version

80cms:
- regenerate NetworkManager connections

90btrfs:
- force preload btrfs module
- Install crypto modules in 90kernel-modules

90crypt:
- cryptroot-ask: no warn if /run/cryptsetup exist
- install crypto modules in 90kernel-modules
- try to catch kernel config changes
- fix force on multiple lines
- pull in remote-cryptsetup.target enablement
- cryptroot-ask: unify /etc/crypttab and rd.luks.key

90dmsquash-live:
- iso-scan.sh: Provide an easy reference to iso-scan device

90kernel-modules:
- remove nfit from static module list (see nvdimm module)
- install crypto modules in 90kernel-modules
- add sg kernel module
- add pci_hyperv
- install block drivers more strictly
- install less modules for hostonly mode
- arm: add drivers/hwmon for arm/arm64

90kernel-network-modules
- on't install iscsi related module (use 95iscsi)

90lvm:
- remove unnecessary ${initdir} from lvm_scan.sh
- fix removal of pvscan from udev rules
- do not add newline to cmdline

90multipath:
- add automatic configuration for multipath
  (adds 'rd.multipath=default' to use the default config)
- install kpartx's 11-dm-parts.rules

90nvdimm:
- new module for NVDIMM support

90ppcmac:
- respect DRACUT_ARCH, don't exclude ppcle

90qemu-net:
- in hostonly mode, only install if network is needed
- install less module for strict hostonly mode

91zipl:
- parse-zipl.sh: honor SYSTEMD_READY

95cifs:
- pass rootflags to mount
- install new softdeps (sha512, gcm, ccm, aead2)

95dasd:
- only install /etc/dasd.conf if present

95dcssblk:
- fix script permissions

95fcoe:
- fix pre-trigger stage by replacing exit with return in lldpad.sh
- default rd.nofcoe to false
- don't install if there is no FCoE hostonly devices

95iscsi:
- fix missing space when compiling cmdline args
- fix ipv6 target discovery

95nfs:
- only install rpc services for NFS < 4 when hostonly is strict
- Change the order of NFS servers during the boot
  (next-server option has higher priority than DHCP-server itself)
- install less module if hostonly mode is strict

95nvmf:
- add module for NVMe-oF
- add NVMe over TCP support

95resume:
- do not resume on iSCSI, FCoE or NBD

95rootfs-block:
- mount-root.sh: fix writing fstab file with missing fsck flag
- only write root argument for block device

95zfcp:
- match simplified rd.zfcp format too

95zfcp_rules:
- parse-zfcp.sh: remove rule existence check

95znet:
- add a rd.znet_ifname= option

98dracut-systemd:
- remove memtrace-ko and rd.memdebug=4 support in dracut
- remove cleanup_trace_mem calls
- dracut-initqueue: Print more useful info in case of timeout
- as of v246 of systemd "syslog" and "syslog-console" switches have been deprecated
- don't wait for root device if remote cryptsetup active

99base:
- dracut-lib.sh: quote variables in parameter expansion patterns
- remove memtrace-ko and rd.memdebug=4 support in dracut
- remove cleanup_trace_mem calls
- see new module 99memstrack
- prevent creating unexpected files on the host when running dracut

99memstrack:
- memstrack is a new tool to track the overall memory usage and
  allocation, which can help off load the improve the builtin module
  memory tracing function in dracut.

99squash:
- don't hardcode the squash sub directories
- improve pre-requirements check
- check require module earlier, and properly

new modules:
- nvmf
- watchdog-modules
- dbus
- network-wicked

removed modules:
- stratis

test suite:
- use dd from /dev/zero, instead of creating files with a hole
- TEST-03-USR-MOUNT/test.sh: increase loglevel
- TEST-12-RAID-DEG/create-root.sh: more udevadm settle
- TEST-35-ISCSI-MULTI: bump disk space
- TEST-41-NBD-NM/Makefile: should be based on TEST-40-NBD not TEST-20-NFS
- TEST-99: exclude /etc/dnf/* from check

dracut-050
==========

dracut:
- support for running on a cross-compiled rootfs, see README.cross
- add support for creating secureboot signed UEFI images
- use microcode found in packed cpio images
- `-k/--kmodir` must now contain "lib/modules/$KERNEL_VERSION"
  use DRACUT_KMODDIR_OVERRIDE=1 to ignore this check
- support the EFI Stub loader's splash image feature.
  `--uefi-splash-image <FILE>`

dracut modules:
- remove bashism in various boot scripts
- emergency mode: use sulogin

fcoe:
- add rd.nofcoe option to disable the FCoE module from the command line

10i18n:
- fix keymaps not getting included sometimes
- use eurlatgr as default console font

iscsi:
- add option `rd.iscsi.testroute`

multipath:
- fix udev rules detection of multipath devices

network:
- support NetworkManager

network-legacy:
- fix classless static route parsing
- ifup: fix typo when calling dhclient --timeout
- ifup: nuke pid and lease files if dhclient failed
- fix ip=dhcp,dhcp6
- use $name instead of $env{INTERFACE} (systemd-udevd regression)

shutdown:
- fix for non-systemd reboot/halt/shutdown commands
- set selinux labels
- fix shutdown with console=null

lsinitrd:
- list squash content as well
- handle UEFI created with dracut --uefi
- make lsinitrd usable for images made with Debian mkinitramfs

dracut-install:
- fixed ldd parsing
- install kernel module dependencies of dependencies
- fixed segfault for hashing NULL pointers
- add support for compressed firmware files
- dracut_mkdir(): create parent directories as needed.

configure:
- Find FTS library with --as-needed

test suite:
- lots of cleanups
- add github actions

new modules:
- rngd
- network-manager
- ppcmac - thermal/fan control modules on PowerPC based Macs

dracut-049
==========
lsinitrd:
- record loaded kernel modules when hostonly mode is enabled
  lsinitrd $image -f */lib/dracut/loaded-kernel-modules.txt
- allow to only unpack certain files

kernel-modules:
- add gpio and pinctrl drivers for arm*/aarch64
- add nfit

kernel-network-modules:
- add vlan kernel modules

ifcfg/write-ifcfg.sh:
- aggregate resolv.conf

livenet:
- Enable OverlayFS overlay in sysroot.mount generator.

dmsquash-live:
- Support a flattened squashfs.img
- Remove obsolete osmin.img processing

dracut-systemd:
- Start systemd-vconsole-setup before dracut-cmdline-ask

iscsi:
- do not install all of /etc/iscsi unless hostonly
- start iscsid even w/o systemd

multipath:
- fixed shutdown

network:
- configure NetworkManager to use dhclient

mdraid:
- fixed uuid handling ":" versus "-"

stratis:
- Add additional binaries

new modules:
- 00warpclock
- 99squash
  Adds support for building a squashed initramfs
- 35network-legacy
  the old 40network
- 35network-manager
  alternative to 35network-legacy
- 90kernel-modules-extra
  adds out-of-tree kernel modules

testsuite:
- now runs on travis
- support new qemu device options
- even runs without kvm now

dracut-048
==========

dracut.sh:
- fixed finding of btrfs devices
- harden dracut against BASH_ENV environment variable
- no more prelinking
- scan and install "external" kernel modules
- fixed instmods with zero input
- rdsosreport: best effort to strip out passwords
- introduce tri-state hostonly mode

   Add a new option --hostonly-mode which accept an <mode> parameter, so we have a tri-state hostonly mode:

        * generic: by passing "--no-hostonly" or not passing anything.
                   "--hostonly-mode" has no effect in such case.
        * sloppy: by passing "--hostonly --hostonly-mode sloppy". This
                  is also the default mode when only "--hostonly" is given.
        * strict: by passing "--hostonly --hostonly-mode strict".

    Sloppy mode is the original hostonly mode, the new introduced strict
    mode will allow modules to ignore more drivers or do some extra job to
    save memory and disk space, while making the image less portable.

    Also introduced a helper function "optional_hostonly" to make it
    easier for modules to leverage new hostonly mode.

    To force install modules only in sloppy hostonly mode, use the form:

    hostonly="$(optional_hostonly)" instmods <modules>

dracut-install:
- don't error out, if no modules were installed
- support modules.softdep

lsinitrd.sh:
- fixed zstd file signature

kernel:
- include all pci/host modules
- add mmc/core for arm
- Include Intel Volume Management Device support

plymouth:
- fix detection of plymouth directory

drm:
- make failing installation of drm modules nonfatal
- include virtio DRM drivers in hostonly initramfs

stratis:
- initial Stratis support

crypt:
- correct s390 arch to include arch-specific crypto modules
- add cmdline rd.luks.partuuid
- add timeout option rd.luks.timeout

shutdown:
- sleep a little, if a process was killed

network:
- introduce ip=either6 option

iscsi:
- replace iscsistart with iscsid

qeth_rules:
- new module to copy qeth rules

multipath-hostonly:
- merged back into multipath

mdraid:
- fixed case if rd.md.uuid is in ID_FS_UUID format

dracut-047
==========
dracut.sh:
- sync initramfs to filesystem with fsfreeze
- introduce "--no-hostonly-default-device"
- disable lsinitrd logging when quiet
- add support for Zstandard compression
- fixed relative paths in --kerneldir
- if /boot/vmlinuz-$version exists use /boot/ as default output dir
- make qemu and qemu-net a default module in non-hostonly mode
- fixed relative symlinks
- support microcode updates for all AMD CPU families
- install all modules-load.d regardless of hostonly
- fixed parsing of "-i" and "--include"
- bump kmod version to >= 23
- enable 'early_microcode' by default
- fixed check_block_and_slaves() for nvme

lsinitrd.sh:
- dismiss "cat" error messages

systemd-bootchart:
- removed

i18n:
- install all keymaps for a given locale
- add correct fontmaps

dmsquash-live:
- fixed systemd unit escape

systemd:
- enable core dumps with systemd from initrd
- fixed setting of timeouts for device units
- emergency.service: use Type=idle and fixed task limit

multipath:
- include files from /etc/multipath/conf.d
- do not fail startup on missing configuration
- start daemon after udev settle
- add shutdown script
- parse kernel commandline option 'multipath=off'
- start before local-fs-pre.target

dracut-emergency:
- optionally print filesystem help

network:
- fixed MTU for bond master
- fixed race condition when wait for networks

fcoe:
- handle CNAs with DCB firmware support
- allow to specify the FCoE mode via the fcoe= parameter
- always set AUTO_VLAN for fcoemon
- add shutdown script
- fixup fcoe-genrules.sh for VN2VN mode
- switch back to using fipvlan for bnx2fc
- add timeout mechanism

crypt:
- add basic LUKS detached header support
- escape backslashes for systemd unit names correctly
- put block_uuid.map into initramfs

dmraid:
- do not delete partitions

dasd_mod:
- do not set module parameters if dasd_cio_free is not present

nfs:
- fix mount if IPv4 address is used in /etc/fstab
- support host being a DNS ALIAS

fips:
- fixed creating path to .hmac of kernel based on BOOT_IMAGE
- turn info calls into fips_info calls
- modprobe failures during manual module loading is not fatal


lunmask:
- add module to handle LUN masking

s390:
- add rd.cio_accept

dcssblk:
- add new module for DCSS block devices

zipl:
- add new module to update s390x configuration

iscsi:
- no more iscsid, either iscsistart or iscsid

integrity:
- support loading x509 into the trusted/builtin .evm keyring
- support X.509-only EVM configuration

plymouth:
- improve distro compatibility

dracut-046
==========

dracut.sh:
- bail out if module directory does not exist
  if people want to build the initramfs without kernel modules,
  then --no-kernel should be specified
- add early microcode support for AMD family 16h
- collect also all modaliases modules from sysfs for hostonly modules
- sync initramfs after creation

network:
- wait for IPv6 RA if using none/static IPv6 assignment
- ipv6 improvements
- Handle curl using libnssckbi for TLS
- fix dhcp classless_static_routes
- dhclient: send client-identifier matching hardware address
- don't arping for point-to-point connections
- only bring up wired network interfaces (no wlan and wwan)

mraid:
- mdraid: wait for rd.md.uuid specified devices to be assembled

crypt:
- handle rd.luks.name

crypt-gpg:
- For GnuPG >= 2.1 support OpenPGP smartcards

kernel-install:
- Skip to create initrd if /etc/machine-id is missing or empty

nfs:
- handle rpcbind /run/rpcbind directory

s390:
- various fixes

dmsquash-live:
- add NTFS support

multipath:
- split out multipath-hostonly module

lvmmerge:
- new module, see README.md in the module directory

dracut-systemd:
- fixed dependencies


dracut-045
==========

Important: dracut now requires libkmod for the dracut-install binary helper,
           which nows handles kernel module installing and filtering.

dracut.sh:
- restorecon final image file
- fail hard, if we find modules and modules.dep is missing
- support --tmpdir as a relative path
- add default path for --uefi

dracut-functions.sh:
- fix check_vol_slaves() volume group name stripping

dracut-install:
- catch ldd message "cannot execute binary file"
- added kernel module handling with libkmod
  Added parameters:
    --module,-m
    --mod-filter-path, -p
    --mod-filter-nopath, -P
    --mod-filter-symbol, -s
    --mod-filter-nosymbol, -S
    --mod-filter-noname, -N
    --silent
    --kerneldir
    --firmwaredirs
- fallback to non-hostonly mode if lsmod fails

lsinitrd:
- new option "--unpack"
- new option "--unpackearly"
- and "--verbose"

general initramfs fixes:
- don't remove 99-cmdline-ask on 'hostonly' cleanup
- call dracut-cmdline-ask.service, if /etc/cmdline.d/*.conf exists
- break at switch_root only for bare rd.break
- add rd.emergency=[reboot|poweroff|halt]
  specifies what action to execute in case of a critical failure
- rd.memdebug=4 gives information, about kernel module memory consumption
  during loading

dmsquash-live:
- fixed livenet-generator execution flag
  and include only, if systemd is used
- fixed dmsquash-live-root.sh for cases where the fstype of the liveimage is squashfs
- fixed typo for rootfs.img
- enable the use of the OverlayFS for the LiveOS root filesystem
  Patch notes:
    Integrate the option to use an OverlayFS as the root filesystem
    into the 90dmsquash-live module for testing purposes.

    The rd.live.overlay.overlayfs option allows one to request an
    OverlayFS overlay.  If a persistent overlay is detected at the
    standard LiveOS path, the overlay & type detected will be used.

    Tested primarily with transient, in-RAM overlay boots on vfat-
    formatted Live USB devices, with persistent overlay directories
    on ext4-formatted Live USB devices, and with embedded, persistent
    overlay directories on vfat-formatted devices. (Persistent overlay
    directories on a vfat-formatted device must be in an embedded
    filesystem that supports the creation of trusted.* extended
    attributes, and must provide valid d_type in readdir responses.)

    The rd.live.overlay.readonly option, which allows a persistent
    overlayfs to be mounted read only through a higher level transient
    overlay directory, has been implemented through the multiple lower
    layers feature of OverlayFS.

    The default transient DM overlay size has been adjusted up to 32 GiB.
    This change supports comparison of transient Device-mapper vs.
    transient OverlayFS overlay performance.  A transient DM overlay
    is a sparse file in memory, so this setting does not consume more
    RAM for legacy applications.  It does permit a user to use all of
    the available root filesystem storage, and fails gently when it is
    consumed, as the available free root filesystem storage on a typical
    LiveOS build is only a few GiB.  Thus, when booted on other-
    than-small RAM systems, the transient DM overlay should not overflow.

    OverlayFS offers the potential to use all of the available free RAM
    or all of the available free disc storage (on non-vfat-devices)
    in its overlay, even beyond the root filesystem available space,
    because the OverlayFS root filesystem is a union of directories on
    two different partitions.

    This patch also cleans up some message spew at shutdown, shortens
    the execution path in a couple of places, and uses persistent
    DM targets where required.

dmraid:
- added "nowatch" option in udev rule, otherwise udev would reread partitions for raid members
- allow booting from degraded MD RAID arrays

shutdown:
- handle readonly /run on shutdown

kernel-modules:
- add all HID drivers, regardless of hostonly mode
  people swap keyboards sometimes and should be able to enter their disk password
- add usb-storage
  To save the rdsosreport.txt to a USB stick, the usb-storage module is needed.
- add xennet
- add nvme

systemd:
- add /etc/machine-info
- fixed systemd-escape call for names beginning with "-"
- install missing drop-in configuration files for
    /etc/systemd/{journal.conf,system.conf}

filesystems:
- add support to F2FS filesystem (fsck and modules)

network:
- fix carrier detection
- correctly set mac address for ip=...:<mtu>:<mac>
- fixed vlan, bonding, bridging, team logic
  call ifup for the slaves and assemble afterwards
- add mtu to list of variables to store in override
- for rd.neednet=0 a bootdev is not needed anymore
- dhclient-script.sh: add classless-static-routes support
- support for iBFT IPv6
- support macaddr in brackets [] (commit 740c46c0224a187d6b5a42b4aa56e173238884cc)
- use arping2, if available
- support multiple default gateways from DHCP server
- fixup VLAN handling
- enhance team support
- differ between ipv6 local and global tentative
- ipv6: wait for a router advertised route
- add 'mtu' parameter for bond options
- use 'ip' instead of 'brctl'

nbd:
- add systemd generator
- use export names instead of port numbers, because port number based
  exports are deprecated and were removed.

fcoe:
- no more /dev/shm state copying

multipath:
- check all /dev/mapper devices if they are multipath devices, not only mpath*

fips:
- fixed .hmac installation in FIPS mode

plymouth:
- also trigger the acpi subsystem

syslog:
- add imjournal.so to read systemd journal
- move start from udev to initqueue/online

caps:
- make it a non default module

livenet:
- support nfs:// urls in livenet-generator

nfs:
- install all nfs modules non-hostonly

crypt:
- support keyfiles embedded in the initramfs

testsuite:
- add TEST-70-BONDBRIDGETEAMVLAN
- make "-cpu host" the default

dracut-044
==========
creation:
- better udev & systemd dir detection
- split dracut-functions.sh in dracut-init.sh and dracut-functions.sh
  dracut-functions.sh can now be sourced by external tools
- detect all btrfs devices needed
- added flag file if initqueue is needed
- don't overwrite anything, if initramfs image file creation failed
- if no compressor is specified, try to find a suitable one
- drop scanning kernel config for CONFIG_MICROCODE_*_EARLY
- remove "_EARLY" from CONFIG_MICROCODE_* checks
- dracut.sh: add command line option for install_i18_all
  --no-hostonly-i18n -> install_i18n_all=yes
  --hostonly-i18n -> install_i18n_all=no
- --no-reproducible to turn off reproducible mode
- dracut-function.sh can now be sourced from outside of dracut
- dracut-init.sh contains all functions, which only can be used from
  within the dracut infrastructure
- support --mount with just mountpoint as a parameter
- removed action_on_fail support
- removed host_modalias concept
- do not create microcode, if no firmware is available
- skip gpg files in microcode generation

initramfs:
- ensure pre-mount (and resume) run before root fsck
- add --online option to initqueue

qemu:
- fixed virtual machine detection

lvm:
- remove all quirk arguments for lvm >= 2.2.221

dmsquash:
- fixup for checkisomd5
- increase timeout for checkisomd5
- use non-persistent metadata snapshots for transient overlays.
- overflow support for persistent snapshot.
- use non-persistent metadata snapshots.
- avoid an overlay for persistent, uncompressed, read-write live installations.

multipath:
- multipath.conf included in hostonly mode
- install all multipath path selector kernel modules

iSCSI:
- use the iBFT initiator name, if found and set
- iscsid now present in the initramfs
- iscsistart is done with systemd-run asynchrone to do things in
  paralllel. Also restarted for every new interface which shows up.
- If rd.iscsi.waitnet (default) is set, iscsistart is done only
  after all interfaces are up.
- If not all interfaces are up and rd.iscsi.testroute (default) is set,
  the route to a iscsi target IP is checked and skipped, if there is none.
- If all things fail, we issue a "dummy" interface iscsiroot to retry
  everything in the initqueue/timeout.

network:
- added DHCP RENEW/REBIND
- IPv4 DHCP lease time now optional (bootp)
- IPv6 nfs parsing
- fixed IPv6 route parsing
- rd.peerdns=0 parameter to disable DHCP nameserver setting
- detect duplicate IPv4 addresses for static addresses
- if interfaces are specified with its enx* name, bind the correspondent MAC to the interface name
- if multiple "ip=" are present on the kernel command line "rd.neednet=1" is assumed
- add options to tweak timeouts
     rd.net.dhcp.retry=<cnt>
         If this option is set, dracut will try to connect via dhcp
         <cnt> times before failing. Default is 1.

     rd.net.timeout.dhcp=<arg>
         If this option is set, dhclient is called with "-timeout <arg>".

     rd.net.timeout.iflink=<seconds>
         Wait <seconds> until link shows up. Default is 60 seconds.

     rd.net.timeout.ifup=<seconds>
         Wait <seconds> until link has state "UP". Default is 20 seconds.

     rd.net.timeout.route=<seconds>
         Wait <seconds> until route shows up. Default is 20 seconds.

     rd.net.timeout.ipv6dad=<seconds>
         Wait <seconds> until IPv6 DAD is finished. Default is 50 seconds.

     rd.net.timeout.ipv6auto=<seconds>
         Wait <seconds> until IPv6 automatic addresses are assigned.
         Default is 40 seconds.

     rd.net.timeout.carrier=<seconds>
         Wait <seconds> until carrier is recognized. Default is 5 seconds.

IMA:
- load signed certificates in the IMA keyring, see modules.d/98integrity/README
- load EVM public key in the kernel _evm keyring

FCoE:
    fcoe: start with fcoemon instead of fipvlan

dracut-043
==========
- add missing dmsquash-generator

dracut-042
==========
- fixed dmsetup shutdown
- new kernel command line option "rd.live.overlay.thin"
    This option changes the underlying mechanism for the overlay in the
    dmsquash module.
    Instead of a plain dm snapshot a dm thin snapshot is used. The advantage
    of the thin snapshot is, that the TRIM command is recognized, which
    means that at runtime, only the occupied blocks will be claimed from
    memory, and freed blocks will really be freed in ram.
- dmsquash: Add squashfs support to rd.live.fsimg
    Previously rd.live.fsimg only supported filesystems residing in
    (compressed) archives.
    Now rd.live.fsimg can also be used when a squashfs image is used.
    This is achieved by extracting the rootfs image from the squashfs and
    then continue with the default routines for rd.live.fsimg.
- lvm: add support for LVM system id
- split up the systemd dracut module
    Basic systemd functionality is in 00systemd now.
    Switching root and the initrd.target is in 00systemd-initrd.
    Dracut additions to the systemd initrd are in 98dracut-systemd.
- support for creating a UEFI boot executable via argument "--uefi"
    With an EFI stub, the kernel, the initramfs and a kernel cmdline can be
    glued together to a single UEFI executable, which can be booted by a
    UEFI BIOS.
- network: split out kernel-network-modules, now in 90kernel-network-modules
- support for ethernet point-to-point connections configured via DHCP
- kernel-modules: install all HID drivers
- dracut.pc pkg-config file
- mount /dev, /dev/shm and /run noexec

dracut-041
==========
- fixed the shutdown loop
- fixed gzip compression for versions, which do not have --rsyncable
- fixed ifcfg generation for persistent interface names
- multipath:
  * new option to turn off multipath "rd.multipath=0" completly
  * preload scsi dh modules
  * start multipathd via systemd service
- do not fail, if user pressed ESC during media check
- fixed systemd-journal by symlinking /var/log to /run/initramfs/log
- initrd-release moved to /usr/lib
- lots of iSCSI fixes
- new "rd.timeout" to specify the systemd JobTimeoutSec for devices
- if $initrd/etc/cmdline.d/* has a "root=" and the kernel cmdline does not,
  generate a mount unit for it
- increased the initqueue timeout for non systemd initramfs to 180s
- $initrd/etc/cmdline.d/ hostonly files are now generated for NFS
- make use of systemd-hibernate-resume, if available
- fixed ldconfig parsing for hwcap output
- network: add support for comma separated autoconf options like ip=eth0:auto6,dhcp
- new parameter "rd.live.overlay.size" to specify the overlay for live images
- changed the test suite for the new sfdisk syntax
- added cache tools for dm-cache setups

dracut-040
==========
- fixed dracut module dependency checks
- fixed test suite

dracut-039
==========
- DRACUT_PATH can now be used to specify the PATH used by dracut
  to search for binaries instead of the default
  /usr/sbin:/sbin:/usr/bin:/bin
  This should be set in the distribution config file
  /usr/lib/dracut/dracut.conf.d/01-dist.conf
- add "--loginstall <DIR>" and loginstall="<DIR>" options
  to record all files, which are installed from the host fs
- "rd.writable.fsimg" - support for read/write filesystem images
- "rd.route" kernel command line parameter added
- "--install-optional" and install_optional_items added
- find plymouth pkglibdir on debian
- torrent support for live images
  root=live:torrent://example.com/liveboot.img.torrent
  and generally added as a download handler
- disable microcode, if the kernel does not support it
- speed up ldconfig_paths()
- more ARM modules
- fixed inst*() functions and "-H" handling
- fixed bridge setup
- added --force-drivers parameter and force_drivers=+ config option
  to enforce driver loading at early boot time
- documented "iso-scan/filename" usage in grub
- various bugfixes

dracut-038
==========
- "rd.cmdline=ask" will ask the user on the console to enter additional
  kernel command line parameters
- "rd.hostonly=0" removes all "hostonly" added custom files,
  which is useful in combination with "rd.auto" or other specific parameters,
  if you want to boot on the same hardware, but the compiled in configuration
  does not match your setup anymore
- inst* functions and dracut-install now accept the "-H" flag, which logs all
  installed files to /lib/dracut/hostonly-files. This is used to remove those
  files, if rd.hostonly is given on the kernel command line
- strstr now only does literal string match,
  please use strglob and strglobin for globs
- fixed unpacking of the microcode image on shutdown
- added systemd-gpt-auto-generator
- fcoe: wait for lldpad to be ready
- network: handle "ip=dhcp6"
- network: DCHPv6: set valid_lft and preferred_lft
- dm: support dm-cache
- fstab: do not mount and fsck from fstab if using systemd
- break at switch_root only for bare rd.break and not for any rd.break=...
- nbd: make use of "--systemd-mark", otherwise it gets killed on switch_root
- fcoe-uefi: fixed cmdline parameter generation
- iscsi: deprecate "ip=ibft", use "rd.iscsi.ibft[=1]" from now on
- "lsinitrd -m" now only lists the dracut modules of the image
- a lot of small bugfixes

dracut-037
==========
- dracut: hostonly_cmdline variable and command line switch
    Toggle hostonly cmdline storing in the initramfs
    --hostonly-cmdline:
        Store kernel command line arguments needed in the initramfs
    --no-hostonly-cmdline:
        Do not store kernel command line arguments needed in the initramfs
- dracut: --mount now understands full fstab lines
- dracut now also includes drivers from the /lib/modules/<version>/updates directory
- dracut: only set the owner of files to 0:0, if generated as non-root
- dracut now directly writes to the initramfs file
- dracut: call lz4 with the legacy flag (linux kernel does not support the new format)
- systemd: rootfs-generator generates JobTimeout=0 units for the root device
- systemd: added the systemd-sysctl service
- systemd: add 80-net-setup-link.rules and .link files for persistent interface renaming
- systemd: make dracut-shutdown.service failure non-fatal
- network: various IPv6 fixes
- network: DCHCP for IPv6
- network: understand ip=.....:<dns1>:<dns2>
- network: parse ibft nameserver settings
- shutdown: if kexec fails, just reboot
- lvm: handle one LV at a time with lvchange
- module-setup.sh:
    New functions require_binaries() and require_any_binary() to be used
    in the check() section of module-setup.sh.
- a lot of small bugfixes

Contributions from:
Harald Hoyer
Alexander Tsoy
Till Maas
Amadeusz Żołnowski
Brian C. Lane
Colin Guthrie
Dave Young
WANG Chao
Shawn W Dunn

dracut-036
==========
- fixed skipcpio signature checking

dracut-035
==========
- changed dracut tarball compression to xz
- new argument "--rebuild"
- add lzo, lz4 compression
- install: install all binaries with <name> found in PATH
- lsinitrd can now handle initramfs images with an early cpio prepended
  (microcode, ACPI tables)
- mkinitrd-suse added as a compat stub for dracut
- lvm: install thin utils for non-hostonly
- resume: fix swap detection in hostonly
- avoid loading unnecessary 32-bit libraries for 64-bit initrds
- crypt: wait for systemd password agents
- crypt: skip crypt swaps with password files
- network: before doing dhcp, dracut now checks, if the link has a carrier
- network: dhclient-script.sh now sets the lease time
- network: include usbnet drivers
- network: include all ethernet drivers
- network: add rd.bootif=0 to ignore BOOTIF
- i18n: introduce i18n_install_all, to install everything i18n related
- support SuSE DASD configurations
- support SuSE zfcp configurations
- support SuSE compressed KEYMAP= setting
- usrmount: always install the module,
  so always mount /usr from within the initramfs
- test/TEST-17-LVM-THIN: new test case for lvm thin pools
- "halt" the machine in systemd mode for die()

dracut-034
==========
- do not run dhcp on parts of assembled network interfaces (bond, bridge)
- add option to turn on/off prelinking
    --prelink, --noprelink
    do_prelink=[yes|no]
- add ACPI table overriding
- do not log to syslog/kmsg/journal for UID != 0
- lvm/mdraid: Fix LVM on MD activation
- bcache module removed (now in bcache-tools upstream)
- mdadm: also install configs from /etc/mdadm.conf.d
- fixes for mdadm-3.2.6+
- mkinitrd: better compat support for SUSE
- fcoe: add FCoE UEFI boot device support
- rootfs-block: add support for the rootfallback= kernel cmdline option

Contributions from:
Thomas Renninger
Alexander Tsoy
Peter Rajnoha
WANG Chao
Harald Hoyer


dracut-033
==========
- improved hostonly device recognition
- improved hostonly module recognition
- add dracut.css for dracut.html
- do not install udev rules from /etc in generic mode
- fixed LABEL= parsing for swap devices
- fixed iBFT network setup
- url-lib.sh: handle 0-size files with curl
- dracut.asc: document debugging dracut on shutdown
- if rd.md=0, use dmraid for imsm and ddf
- skip empty dracut modules
- removed caching of kernel cmdline
- fixed iso-scan, if the loop device driver is a kernel module
- bcache: support new blkid
- fixed ifup udev rules
- ifup with dhcp, if no "ip=" specified for the interface

Contributions from:
WANG Chao
Colin Walters
Harald Hoyer


dracut-032
==========
- add parameter --print-cmdline
    This prints the kernel command line parameters for the current disk
    layout.
    $ dracut --print-cmdline
    rd.luks.uuid=luks-e68c8906-6542-4a26-83c4-91b4dd9f0471
    rd.lvm.lv=debian/root rd.lvm.lv=debian/usr root=/dev/mapper/debian-root
    rootflags=rw,relatime,errors=remount-ro,user_xattr,barrier=1,data=ordered
    rootfstype=ext4
- dracut.sh: add --persistent-policy option and persistent_policy conf option
    --persistent-policy <policy>:
        Use <policy> to address disks and partitions.
        <policy> can be any directory name found in /dev/disk.
        E.g. "by-uuid", "by-label"
- dracut now creates the initramfs without udevadm
  that means the udev database does not have to populated
  and the initramfs can be built in a chroot with
  /sys /dev /proc mounted
- renamed dracut_install() to inst_multiple() for consistent naming
- if $libdirs is unset, fall back to ld.so.cache paths
- always assemble /usr device in initramfs
- bash module added (disable it, if you really want dash)
- continue to boot, if the main loop times out, in systemd mode
- removed inst*() shell pure versions, dracut-install binary is in charge now
- fixed ifcfg file generation for vlan
- do not include adjtime and localtime anymore
- fixed generation of zfcp.conf of CMS setups
- install vt102 terminfo
  dracut_install() is still there for backwards compat
- do not strip files in FIPS mode
- fixed iBFT interface configuration
- fs-lib: install fsck and fsck.ext*
- shutdown: fixed killall_proc_mountpoint()
- network: also wait for ethernet interfaces to setup
- fixed checking for FIPS mode

Contributions from:
Harald Hoyer
WANG Chao
Baoquan He
Daniel Schaal
Dave Young
James Lee
Radek Vykydal


dracut-031
==========
- do not include the resume dracut module in hostonly mode,
  if no swap is present
- don't warn twice about omitted modules
- use systemd-cat for logging on systemd systems, if logfile is unset
- fixed PARTUUID parsing
- support kernel module signing keys
- do not install the usrmount dracut module in hostonly mode,
  if /sbin/init does not live in /usr
- add debian udev rule files
- add support for bcache
- network: handle bootif style interfaces
  e.g. ip=77-77-6f-6f-64-73:dhcp
- add support for kmod static devnodes
- add vlan support for iBFT

Contributions from:
Harald Hoyer
Amadeusz Żołnowski
Brandon Philips
Colin Walters
James Lee
Kyle McMartin
Peter Jones

dracut-030
==========
- support new persistent network interface names
- fix findmnt calls, prevents hang on stale NFS mounts
- add systemd.slice and slice.target units
- major shell cleanup
- support root=PARTLABEL= and root=PARTUUID=
- terminfo: only install l/linux v/vt100 and v/vt220
- unset all LC_* and LANG, 10% faster
- fixed dependency loop for dracut-cmdline.service
- do not wait_for_dev for the root devices
- do not wait_for_dev for devices, if dracut-initqueue is not needed
- support early microcode loading with --early-microcode
- dmraid, let dmraid setup its own partitions
- sosreport renamed to rdsosreport

Contributions from:
Harald Hoyer
Konrad Rzeszutek Wilk
WANG Chao

dracut-029
==========
- wait for IPv6 autoconfiguration
- i18n: make the default font configurable
  To set the default font for your distribution, add
  i18n_default_font="latarcyrheb-sun16"
  to your /lib/dracut/dracut.conf.d/01-dist.conf distribution config.
- proper handle "rd.break" in systemd mode before switch-root
- systemd: make unit files symlinks
- build without dash requirement
- add dracut-shutdown.service.8 manpage
- handle MACs for "ip="
  "ip=77-77-6f-6f-64-73:dhcp"
- don't explode when mixing BOOTIF and ip=
- 90lvm/module-setup.sh: redirect error message of lvs to /dev/null

Contributions from:
Harald Hoyer
Will Woods
Baoquan He

dracut-028
==========
- full integration of crypto devs in systemd logic
- support for bridge over team and vlan tagged team
- support multiple bonding interfaces
- new kernel command line param "rd.action_on_fail"
  to control the emergency action
- support for bridge over a vlan tagged interface
- support for "iso-scan/filename" kernel parameter
- lsinitrd got some love and does not use "file" anymore
- fixed issue with noexec mounted tmp dirs
- FIPS mode fixed
- dracut_install got some love
- fixed some /usr mounting problems
- ifcfg dracut module got some love and fixes
- default installed font is now latarcyrheb-sun16
- new parameters rd.live.dir and rd.live.squashimg
- lvm: add tools for thin provisioning
- also install non-hwcap libs
- setup correct system time and time zone in initrd
- s390: fixed cms setup
- add systemd-udevd persistent network interface naming

Contributions from:
Harald Hoyer
Kamil Rytarowski
WANG Chao
Baoquan He
Adam Williamson
Colin Guthrie
Dan Horák
Dave Young
Dennis Gilmore
Dennis Schridde

dracut-027
==========
- dracut now has bash-completion
- require bash version 4
- systemd module now requires systemd >= 199
- dracut makes use of native systemd initrd units
- added hooks for new-kernel-pkg and kernel-install
- hostonly is now default for fedora
- comply with the BootLoaderSpec paths
  http://www.freedesktop.org/wiki/Specifications/BootLoaderSpec
- added rescue module
- host_fs_types is now a hashmap
- new dracut argument "--regenerate-all"
- new dracut argument "--noimageifnotneeded"
- new man page dracut.bootup
- install all host filesystem drivers
- use -D_FILE_OFFSET_BITS=64 to build dracut-install

dracut-026
==========
- introduce /usr/lib/dracut/dracut.conf.d/ drop-in directory

  /usr/lib/dracut/dracut.conf.d/*.conf can be overwritten by the same
  filenames in /etc/dracut.conf.d.

  Packages should use /usr/lib/dracut/dracut.conf.d rather than
  /etc/dracut.conf.d for drop-in configuration files.

  /etc/dracut.conf and /etc/dracut.conf.d belong to the system administrator.

- uses systemd-198 native initrd units
- totally rely on the fstab-generator in systemd mode for block devices
- dracut systemd now uses dracut.target rather than basic.target
- dracut systemd services optimize themselves away
- fixed hostonly parameter generation
- turn off curl globbing (fixes IPv6)
- modify the udev rules on install and not runtime time
- enable initramfs building without kernel modules (fixed regression)
- in the initqueue/timeout,
  reset the main loop counter, as we see new udev events or initqueue/work
- fixed udev rule installation

dracut-025
==========
- do not strip signed kernel modules
- add sosreport script and generate /run/initramfs/sosreport.txt
- make short uuid specification for allow-discards work
- turn off RateLimit for the systemd journal
- fixed MAC address assignment
- add systemd checkisomd5 service
- splitout drm kernel modules from plymouth module
- add 'swapoff' to initramfs to fix shutdown/reboot
- add team device support
- add pre-shutdown hook
- kill all processes in shutdown and report remaining ones
- "--device" changed to "--add-device" and "add_device=" added for conf files
- add memory usage trace to different hook points
- cope with optional field #7 in /proc/self/mountinfo
- lots of small bugfixes

dracut-024
==========
- new dracut option "--device"
- new dracut kernel command line options "rd.auto"
- new dracut kernel command line options "rd.noverifyssl"
- new dracut option "--kernel-cmdline" and "kernel_cmdline" option for default parameters
- fixes for systemd and crypto
- fix for kexec in shutdown, if not included in initramfs
- create the initramfs non-world readable
- prelink/preunlink in the initramfs
- strip binaries in the initramfs by default now
- various FIPS fixes
- various dracut-install fixes

dracut-023
==========
- resume from hibernate fixes
- -N option for --no-hostonly
- support for systemd crypto handling
- new dracut module "crypt-loop"
- deprecate the old kernel command line options
- more documentation
- honor CFLAGS for dracut-install build
- multipath fixes
- / is mounted according to rootflags parameter but forced ro at first.
  Later it is remounted according to /etc/fstab + rootflags parameter
  and "ro"/"rw".
- support for xfs / reiserfs separate journal device
- new "ro_mnt" option to force ro mount of / and /usr
- root on cifs support
- dracut-install: fixed issue for /var/tmp containing a symlink
- only lazy resolve with ldd, if the /var/tmp partition is not mounted with "noexec"
- i18n: fixed inclusion of "include" keymaps

dracut-022
==========
- fixed host-only kernel module bug

dracut-021
==========
- fixed systemd in the initramfs (requires systemd >= 187)
- dracut-install: massive speedup with /var on the same filesystem with COW copy
- dracut-install: moved to /usr/lib/dracut until it becomes a general purpose tool
- new options: "rd.usrmount.ro" and "rd.skipfsck"
- less mount/umount
- apply "ro" on the kernel command line also to /usr
- mount according to fstab, if neither "ro" or "rw" is specified
- skip fsck for xfs and btrfs. remount is enough
- give emergency_shell if /usr mount failed
- dracut now uses getopt:
  * options can be position independent now!!
  * we can now use --option=<arg>
- added option "--kver=<kernel-version>", and the image location can be omitted
  # dracut --kver 3.5.0-0.rc7.git1.2.fc18.x86_64
- dracut.sh: for --include copy also the symbolic links
- man pages: lsinitrd and mkinitrd added
- network: We do not support renaming in the kernel namespace anymore (as udev does
  that not anymore). So, if a user wants to use ifname, he has to rename
  to a custom namespace. "eth[0-9]+" is not allowed anymore. !!!!!
- resume: moved the resume process to the initqueue.
  This should prevent accidently mounting the root file system.
- testsuite: add support for: make V=1 TESTS="01 20 40" check
    $ sudo make V=1 clean check
    now runs the testsuite in verbose mode

    $ sudo make TESTS="01 20 40" clean check
    now only runs the 01, 20 and 40 tests.

dracut-020
==========
- changed rd.dasd kernel parameter
- arm kernel modules added to kernel-modules
- make udevdir systemdutildir systemdsystemunitdir global vars
  your distribution should ship those settings in
  /etc/dracut.conf.d/01-distro.conf
  see dracut.conf.d/fedora.conf.example
- kernel modules are now only handled with /sys/modules and modules.dep
- systemd fixups
- mdraid: wait for md devices to be clean, before shutdown
- ifup fixed for ipv6
- add PARTUUID as root=PARTUUID=<partition uuid> parameter
- fixed instmods() return code and set pipefail globally
- add 04watchdog dracut module
- dracut-shutdown.service: fixed ordering to be before shutdown.target
- make use of "ln -r" instead of shell functions, if new coreutils is installed
- network: support vlan tagged bonding
- new dracut module qemu and qemu-net to install all kernel driver
- fs-lib/fs-lib.sh: removed test mounting of btrfs and xfs
- no more "mknod" in the initramfs!!
- replaced all "tr" calls with "sed"
- speedup with lazy kernel module dependency resolving
- lots of speedup optimizations and last but not least
- dracut-install:
  - new binary to significanlty speedup the installation process
  - dracut-functions.sh makes use of it, if installed


dracut-019
==========
- initqueue/online hook
- fixes for ifcfg write out
- rootfs-block: avoid remount when options don't change
- Debian multiarch support
- virtfs root filesystem support
- cope with systemd-udevd
- mount tmpfs with strictatime
- include all kernel/drivers/net/phy drivers
- add debug_on() and debug_off() functions
- add arguments for source_hook() and source_all()
- cleanup hook
- plymouth: get consoledev from /sys/class/tty/console/active
- experimental systemd dracut module for systemd in the initramfs
- install xhci-hcd kernel module
- dracut: new "--mount" option
- lsinitrd: new option --printsize
- ARM storage kernel modules added
- s390 cms conf file support
- /etc/initrd-release in the initrd
- vlan support
- full bonding and bridge support
- removed scsi_wait_scan kernel module from standard install
- support rd.luks.allow-discards and honor options in crypttab
- lots of bugfixes

dracut-018
==========
- lvm: ignore lvm mirrors
- lsinitrd: handle LZMA images
- iscsi: add rd.iscsi.param
- iscsi: add iscsi interface binding
- new module cms to read and handle z-Series cms config files
- fixed fstab.sys handling
- new dracut option "--tmpdir"
- new dracut option "--no-hostonly"
- nbd: name based nbd connects
- converted manpage and documentation source to asciidoc
- write-ifcfg fixes and cleanups
- ifup is now done in the initqueue
- netroot cleanup
- initqueue/online is now for hooks, which require network
- no more /tmp/root.info
- 98pollcdrom: factored out the ugly cdrom polling in the main loop
- simplified rd.luks.uuid testing
- removed "egrep" and "ls" calls
- speedup kernel module installation
- make bzip2 optional
- lots of bugfixes

dracut-017
==========
- a _lot_ faster than dracut-016 in image creation
- systemd service dracut-shutdown.service
- livenet fixes
- ssh-client module install fix
- root=iscsi:... fixed
- lots of restructuring and optimizing in dracut-functions.sh
- usrmount: honor fs_passno in /etc/fstab
- renamed all shell scripts to .sh
- new option "--omit-drivers" and config option "omit_drivers"
- hostonly mode fixups

dracut-016
==========
- fixed lsinitrd
- honor binaries in sbin first
- fixed usrmount module
- added systemd service for shutdown
- fixed terminfo on distros with /usr/share/terminfo
- reload udev rules after "pre-trigger" hook
- improved test suite
- new parameter "--omit-drivers" and new conf param omit_drivers
- "--offroot" support for mdraid
- new libs: net-lib.sh, nfs-lib.sh, url-lib.sh, img-lib.sh
  full of functions to use in your dracut module

dracut-015
==========
- hostonly mode automatically adds command line options for root and /usr
- --add-fstab --mount parameters
- ssh-client module
- --ctty option: add job control
- cleanup /run/initramfs
- convertfs module
- /sbin/ifup can be called directly
- support kernel modules compressed with xz
- s390 iscsi modules added
- terminfo module
- lsinitrd can handle concatened images
- lsinitrd can sort by size

dracut-014
==========
- new dracut arguments:
  --lvmconf
  --nolvmconf
  --fscks [LIST]
  --nofscks
- new .conf options:
  install_items
  fscks
  nofscks
- new kernel options:
  rd.md.ddf
  rd.md.waitclean
  plymouth.enable
- dracut move from /sbin to /usr/bin
- dracut modules dir moved from /usr/share/dracut to /usr/lib/dracut
- profiling with "dracut --profile"
- new TEST-16-DMSQUASH, test for Fedora LiveCDs
- speedup of initramfs creation
- ask_for_password fallback to CLI
- mdraid completely switched to incremental assembly
- no more cdrom polling
- "switch_root" breakpoint is now very late
- /dev/live is gone
- /dev/root is gone
- fs-lib dracut module for fscks added
- xen dracut module removed
- usb mass storage kernel drivers now included
- usrmount dracut module added:
  mount /usr if found in /sysroot/etc/fstab
- only include fsck helper needed for hostonly
- fcoe: support for bnx2fc
- support iSCSI drivers: qla4xxx, cxgb3i, cxgb4i, bnx2i, be2iscsi
- fips-aesni dracut module added
- add install_items to dracut.conf
    install_items+=" <file>[ <file> ...] "
- speedup internal testsuite
- internal testsuite: store temporary data in a temporary dir

dracut-013
==========
- speedup of initramfs creation
- fixed inst_dir for symbolic links
- add unix kernel module

dracut-012
==========
- better fsck handling
- fixed wait condition for LVM volumes
- fix for hardlinks (welcome Debian! :-)
- shutdown bugfixes
- automatic busybox symlink creation
- try to mount /usr, if init points to a path in /usr
- btrfs with multiple devices
- "--force-add" option for dracut, to force-add dracut modules,
  without hostonly checks
- lsinitrd also display the initramfs size in human readable form
- livenet module, to mount live-isos over http
- masterkey,ecryptfs,integrity security modules
- initqueue/timeout queue e.g. for starting degraded raids
- "make rpm" creates an rpm with an increasing release number from any
  git checkout
- support lvm mirrors
- start degraded lvm mirrors after a timeout
- start degraded md raids after a timeout
- getarg() now returns wildcards without file matching to the current fs
- lots of bugfixes

dracut-011
==========
- use udev-168 features for shutting down udev
- introduce "--prefix" to put all initramfs files in e.g "/run/initramfs"
- new shutdown script (called by systemd >= 030) to disassemble the root device
- lots of bugfixes
- new module for gpg-encrypted keys - 91crypt-gpg

dracut-010
==========
- lots of bugfixes
- plymouth: use /run/plymouth/pid instead of /run/initramfs/plymouth
- add "/lib/firmware/updates" to default firmware path

dracut-009
==========
- dracut generator
  - dracut-logger
  - xz compression
  - better argument handling

- initramfs
  - hooks moved to /lib/dracut/hooks in initramfs
  - rd.driver.{blacklist|pre|post} accept comma separated driver list
  - iSCSI: iSCSI Boot Firmware Table (iBFT) support
  - support for /run
  - live image: support for generic rootfs.img (instead of ext3fs.img)
  - caps module
  - FCoE: EDD support

dracut-008
==========
- removed --ignore-kernel-modules option (no longer necessary)
- renamed kernel command line arguments to follow the rd. naming scheme
- merged check, install, installkernel to module-setup.sh
- support for bzip2 and xz compressed initramfs images.
- source code beautification
- lots of documentation
- lsinitrd: "catinitrd" functionality
- dracut: --list-modules
- lvm: support for dynamic LVM SNAPSHOT root volume
- 95fstab-sys: mount all /etc/fstab.sys volumes before switch_root
- 96insmodpost dracut module
- rd.shell=1 per default
- rootfs-block:mount-root.sh add fsck
- busybox shell replacements module
- honor old "real_init="
- 97biosdevname dracut module

dracut-007
==========
- module i18n is no longer fedora/red hat specific (Amadeusz Żołnowski)
- distribution specific conf file
- bootchartd support
- debug module now has fsck
- use "hardlink", if available, to save some space
- /etc/dracut.conf can be overwritten by settings in /etc/dracut.conf.d/*.conf
- gentoo splash module
- --ignore-kernel-modules option
- crypto keys on external devices support
- bugfixes

dracut-006
==========
- fixed mdraid with IMSM
- fixed dracut manpages
- dmraid parse different error messages
- add cdrom polling mechanism for slow cdroms
- add module btrfs
- add btrfsctl scan for btrfs multi-devices (raid)
- teach dmsquash live-root to use rootflags
- trigger udev with action=add
- fixed add_drivers handling
- add sr_mod
- use pigz instead of gzip, if available
- boot from LVM mirrors and snapshots
- iscsi: add support for multiple netroot=iscsi:
- Support old version of module-init-tools
- got rid of rdnetdebug
- fixed "ip=auto6"
- dracut.conf: use "+=" as default for config variables
- bugfixes

dracut-005
==========
- dcb support to dracut's FCoE support
- add readonly overlay support for dmsquash
- add keyboard kernel modules
- dracut.conf: added add_dracutmodules
- add /etc/dracut.conf.d
- add preliminary IPv6 support
- bugfixes

dracut-004
==========
- dracut-lib: read multiple lines from $init/etc/cmdline
- lsinitrd and mkinitrd
- dmsquash: add support for loopmounted *.iso files
- lvm: add rd_LVM_LV and "--poll n"
- user suspend support
- add additional drivers in host-only mode, too
- improved emergency shell
- support for compressed kernel modules
- support for loading Xen modules
- rdloaddriver kernel command line parameter
- man pages for dracut-catimages and dracut-gencmdline
- bugfixes

dracut-003
==========
- add debian package modules
- add dracut.conf manpage
- add module 90multipath
- add module 01fips
- crypt: ignore devices in /etc/crypttab (root is not in there)
  unless rd_NO_CRYPTTAB is specified
- kernel-modules: add scsi_dh scsi_dh_rdac scsi_dh_emc
- add multinic support
- add s390 zfcp support
- add s390 dasd support
- add s390 network support
- fixed dracut-gencmdline for root=UUID or LABEL
- do not destroy assembled raid arrays if mdadm.conf present
- mount /dev/shm
- let udevd not resolve group and user names
- moved network from udev to initqueue
- improved debug output: specifying "rdinitdebug" now logs
  to dmesg, console and /init.log
- strip kernel modules which have no x bit set
- redirect stdin, stdout, stderr all RW to /dev/console
  so the user can use "less" to view /init.log and dmesg
- add new device mapper udev rules and dmeventd
- fixed dracut-gencmdline for root=UUID or LABEL
- do not destroy assembled raid arrays if mdadm.conf present
- mount /dev/shm
- let udevd not resolve group and user names
- preserve timestamps of tools on initramfs generation
- generate symlinks for binaries correctly
- moved network from udev to initqueue
- mount nfs3 with nfsvers=3 option and retry with nfsvers=2
- fixed nbd initqueue-finished
- improved debug output: specifying "rdinitdebug" now logs
  to dmesg, console and /init.log
- strip kernel modules which have no x bit set
- redirect stdin, stdout, stderr all RW to /dev/console
  so the user can use "less" to view /init.log and dmesg
- make install of new dm/lvm udev rules optionally
- add new device mapper udev rules and dmeventd
- Fix LiveCD boot regression
- bail out if selinux policy could not be loaded and
  selinux=0 not specified on kernel command line
- do not cleanup dmraids
- copy over lvm.conf

dracut-002
==========
- add ifname= argument for persistent netdev names
- new /initqueue-finished to check if the main loop can be left
- copy mdadm.conf if --mdadmconf set or mdadmconf in dracut.conf
- plymouth: use plymouth-populate-initrd
- add add_drivers for dracut and dracut.conf
- add modprobe scsi_wait_scan to be sure everything was scanned
- fix for several problems with md raid containers
- fix for selinux policy loading
- fix for mdraid for IMSM
- fix for bug, which prevents installing 61-persistent-storage.rules (bug #520109)
- fix for missing grep for md

dracut-001
==========
- better --hostonly checks
- better lvm/mdraid/dmraid handling
- fcoe booting support
    Supported cmdline formats:
    fcoe=<networkdevice>:<dcb|nodcb>
    fcoe=<macaddress>:<dcb|nodcb>

    Note currently only nodcb is supported, the dcb option is reserved for
    future use.

    Note letters in the macaddress must be lowercase!

    Examples:
    fcoe=eth0:nodcb
    fcoe=4A:3F:4C:04:F8:D7:nodcb

- Syslog support for dracut
    This module provides syslog functionality in the initrd.
    This is especially interesting when complex configuration being
    used to provide access to the device the rootfs resides on.


dracut-0.9
==========
- let plymouth attach to the terminal (nice text output now)
- new kernel command line parameter "rdinfo" show dracut output, even when
  "quiet" is specified
- rd_LUKS_UUID is now handled correctly
- dracut-gencmdline: rd_LUKS_UUID and rd_MD_UUID is now correctly generated
- now generates initrd-generic with around 15MB
- smaller bugfixes

dracut-0.8
==========
- iSCSI with username and password
- support for live images (dmsquashed live images)
- iscsi_firmware fixes
- smaller images
- bugfixes

dracut-0.7
==========
- dracut:     strip binaries in initramfs

           --strip
                  strip binaries in the initramfs (default)

           --nostrip
                  do not strip binaries in the initramfs
- dracut-catimages

    Usage: ./dracut-catimages [OPTION]... <initramfs> <base image>
    [<image>...]
    Creates initial ramdisk image by concatenating several images from the
    command
    line and /boot/dracut/

      -f, --force           Overwrite existing initramfs file.
      -i, --imagedir        Directory with additional images to add
                            (default: /boot/dracut/)
      -o, --overlaydir      Overlay directory, which contains files that
                            will be used to create an additional image
      --nooverlay           Do not use the overlay directory
      --noimagedir          Do not use the additional image directory
      -h, --help            This message
      --debug               Output debug information of the build process
      -v, --verbose         Verbose output during the build process

- s390 dasd support

dracut-0.6
==========
- dracut: add --kernel-only and --no-kernel arguments

           --kernel-only
                  only install kernel drivers and firmware files

           --no-kernel
                  do not install kernel drivers and firmware files

    All kernel module related install commands moved from "install"
    to "installkernel".

    For "--kernel-only" all installkernel scripts of the specified
    modules are used, regardless of any checks, so that all modules
    which might be needed by any dracut generic image are in.

    The basic idea is to create two images. One image with the kernel
    modules and one without. So if the kernel changes, you only have
    to replace one image.

    Grub and the kernel can handle multiple images, so grub entry can
    look like this:

    title Fedora (2.6.29.5-191.fc11.i586)
            root (hd0,0)
            kernel /vmlinuz-2.6.29.5-191.fc11.i586 ro rhgb quiet
            initrd /initrd-20090722.img /initrd-kernel-2.6.29.5-191.fc11.i586.img /initrd-config.img

    initrd-20090722.img
      the image provided by the initrd rpm
      one old backup version is kept like with the kernel

    initrd-kernel-2.6.29.5-191.fc11.i586.img
      the image provided by the kernel rpm

    initrd-config.img
      optional image with local configuration files

- dracut: add --kmoddir directory, where to look for kernel modules

           -k, --kmoddir [DIR]
                  specify the directory, where to look for kernel modules



dracut-0.5
==========
- more generic (all plymouth modules, all keyboards, all console fonts)
- more kernel command line parameters (see also man dracut(8))
- a helper tool, which generates the kernel command line (dracut-gencmdline)
- bridged network boot
- a lot of new command line parameter

dracut-0.4
==========
- bugfixes
- firmware loading support
- new internal queue (initqueue)
    initqueue now loops until /dev/root exists or root is mounted

    init now has the following points to inject scripts:

    /cmdline/*.sh
       scripts for command line parsing

    /pre-udev/*.sh
       scripts to run before udev is started

    /pre-trigger/*.sh
       scripts to run before the main udev trigger is pulled

    /initqueue/*.sh
       runs in parallel to the udev trigger
       Udev events can add scripts here with /sbin/initqueue.
       If /sbin/initqueue is called with the "--onetime" option, the script
       will be removed after it was run.
       If /initqueue/work is created and udev >= 143 then this loop can
       process the jobs in parallel to the udevtrigger.
       If the udev queue is empty and no root device is found or no root
       filesystem was mounted, the user will be dropped to a shell after
       a timeout.
       Scripts can remove themselves from the initqueue by "rm $job".

    /pre-mount/*.sh
       scripts to run before the root filesystem is mounted
       NFS is an exception, because it has no device node to be created
       and mounts in the udev events

    /mount/*.sh
       scripts to mount the root filesystem
       NFS is an exception, because it has no device node to be created
       and mounts in the udev events
       If the udev queue is empty and no root device is found or no root
       filesystem was mounted, the user will be dropped to a shell after
       a timeout.

    /pre-pivot/*.sh
       scripts to run before the real init is executed and the initramfs
       disappears
       All processes started before should be killed here.

    The behaviour of the dmraid module demonstrates how to use the new
    mechanism. If it detects a device which is part of a raidmember from a
    udev rule, it installs a job to scan for dmraid devices, if the udev
    queue is empty. After a scan, it removes itsself from the queue.



dracut-0.3
==========

- first public version

