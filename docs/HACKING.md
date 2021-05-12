# Dracut Developer Guidelines

## git

Currently dracut lives on github.com and kernel.org.

* https://github.com/dracutdevs/dracut.git
* https://git.kernel.org/pub/scm/boot/dracut/dracut.git

Pull requests should be filed preferably on github nowadays.

### Code Format

It is recommended, that you install a plugin for your editor, which reads in `.editorconfig`.
Additionally `emacs` and `vim` config files are provided for convenience.

To reformat C files use `astyle`:
```console
$ astyle --options=.astylerc <FILE>
```

For convenience there is also a Makefile `indent-c` target `make indent-c`.

To reformat shell files use `shfmt`:

```console
$ shfmt_version=3.2.4
$ wget "https://github.com/mvdan/sh/releases/download/v${shfmt_version}/shfmt_v${shfmt_version}_linux_amd64" -O shfmt
$ chmod u+x shfmt
$ ./shfmt -w -s .
```

or

```console
$ GO111MODULE=on go get mvdan.cc/sh/v3/cmd/shfmt
$ $GOPATH/bin/shfmt -w -s .
```

or if `shfmt` is already in your `PATH`, use `make indent`.

Some IDEs already have support for shfmt.

For convenience the `make indent` Makefile target also calls shfmt, if it is in `$PATH`.

### Commit Messages

Commit messages should answer these questions:

* What?: a short summary of what you changed in the subject line.
* Why?: what the intended outcome of the change is (arguably the most important piece of information that should go into a message).
* How?: if multiple approaches for achieving your goal were available, you also want to explain why you chose the used implementation strategy.
  Note that you should not explain how your change achieves your goal in your commit message.
  That should be obvious from the code itself.
  If you cannot achieve that clarity with the used programming language, use comments within the code instead.

The commit message is primarily the place for documenting the why.

Commit message titles should follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

Format is `<type>[optional scope]: <description>`, where `type` is one of:

* fix: A bug fix
* feat: A new feature
* perf: A code change that improves performance
* refactor: A code change that neither fixes a bug nor adds a feature
* style: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
* test: Adding missing tests or correcting existing tests
* docs: Documentation only changes
* revert: Reverts a previous commit
* chore: Other changes that don't modify src or test files
* build: Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm)
* ci: Changes to our CI configuration files and scripts (example scopes: Travis, Circle, BrowserStack, SauceLabs)

`scope` should be the module name (without numbers) or:

* cli: for the dracut command line interface
* rt: for the dracut initramfs runtime logic
* functions: for general purpose dracut functions

Commit messages are checked with [Commisery](https://github.com/tomtom-international/commisery).

## Writing modules

Some general rules for writing modules:

* Use one of the inst family of functions to actually install files
  on to the initramfs.  They handle mangling the pathnames and (for binaries,
  scripts, and kernel modules) installing dependencies as appropriate so
  you do not have to.
* Scripts that end up on the initramfs should be POSIX compliant. dracut
  will try to use /bin/dash as /bin/sh for the initramfs if it is available,
  so you should install it on your system -- dash aims for strict POSIX
  compliance to the extent possible.
* Hooks MUST be POSIX compliant -- they are sourced by the init script,
  and having a bashism break your user's ability to boot really sucks.
* Generator modules should have a two digit numeric prefix -- they run in
  ascending sort order. Anything in the 90-99 range is stuff that dracut
  relies on, so try not to break those hooks.
* Hooks must have a .sh extension.
* Generator modules are described in more detail later on.
* We have some breakpoints for debugging your hooks.  If you pass 'rdbreak'
  as a kernel parameter, the initramfs will drop to a shell just before
  switching to a new root. You can pass 'rdbreak=hookpoint', and the initramfs
  will break just before hooks in that hookpoint run.

Also, there is an attempt to keep things as distribution-agnostic as
possible.  Every distribution has their own tool here and it's not
something which is really interesting to have separate across them.
So contributions to help decrease the distro-dependencies are welcome.

Most of the functionality that dracut implements are actually implemented
by dracut modules.  dracut modules live in modules.d, and have the following
structure:

```
dracut_install_dir/modules.d/
	00modname/
		module-setup.sh
		check
		<other files as needed by the hook>
```

`00modname`: The name of the module prefixed by a two-digit numeric sort code.
	   The numeric code must be present and in the range of 00 - 99.
	   Modules with lower numbers are installed first.  This is important
	   because the dracut install functions (which install files onto
	   the initrd) refuse to overwrite already installed files. This makes
	   it easy for an earlier module to override the functionality of a
	   later module, so that you can have a distro or system specific
	   module override or modify the functionality of a generic module
	   without having to patch the more generic module.

`module-setup.sh`:
	 dracut sources this script to install the functionality that a
	 module implements onto the initrd.  For the most part, this amounts
	 to copying files from the host system onto the initrd in a controlled
	 manner.

`install()`:
	 This function of module-setup.sh is called to install all
	 non-kernel files. dracut supplies several install functions that are
	 specialized for different file types.  Browse through dracut-functions
	 fore more details.  dracut also provides a $moddir variable if you
	 need to install a file from the module directory, such as an initrd
	 hook, a udev rule, or a specialized executable.

`installkernel()`:
	 This function of module-setup.sh is called to install all
	 kernel related files.


`check()`:
       dracut calls this function to check and see if a module can be installed
       on the initrd.

       When called without options, check should check to make sure that
       any files it needs to install into the initrd from the host system
       are present.  It should exit with a 0 if they are, and a 1 if they are
       not.

       When called with $hostonly set, it should perform the same check
       that it would without it set, and it should also check to see if the
       functionality the module implements is being used on the host system.
       For example, if this module handles installing support for LUKS
       encrypted volumes, it should return 0 if all the tools to handle
       encrpted volumes are available and the host system has the root
       partition on an encrypted volume, 1 otherwise.

`depends()`:
       This function should output a list of dracut modules
       that it relies upon.  An example would be the nfs and iscsi modules,
       which rely on the network module to detect and configure network
       interfaces.

Any other files in the module will not be touched by dracut directly.

You are encouraged to provide a README that describes what the module is for.


### Hooks

init has the following hook points to inject scripts:

`/lib/dracut/hooks/cmdline/*.sh`
   scripts for command line parsing

`/lib/dracut/hooks/pre-udev/*.sh`
   scripts to run before udev is started

`/lib/dracut/hooks/pre-trigger/*.sh`
   scripts to run before the main udev trigger is pulled

`/lib/dracut/hooks/initqueue/*.sh`
   runs in parallel to the udev trigger
   Udev events can add scripts here with /sbin/initqueue.
   If /sbin/initqueue is called with the "--onetime" option, the script
   will be removed after it was run.
   If /lib/dracut/hooks/initqueue/work is created and udev >= 143 then
   this loop can process the jobs in parallel to the udevtrigger.
   If the udev queue is empty and no root device is found or no root
   filesystem was mounted, the user will be dropped to a shell after
   a timeout.
   Scripts can remove themselves from the initqueue by "rm $job".

`/lib/dracut/hooks/pre-mount/*.sh`
   scripts to run before the root filesystem is mounted
   Network filesystems like NFS that do not use device files are an
   exception. Root can be mounted already at this point.

`/lib/dracut/hooks/mount/*.sh`
   scripts to mount the root filesystem
   If the udev queue is empty and no root device is found or no root
   filesystem was mounted, the user will be dropped to a shell after
   a timeout.

`/lib/dracut/hooks/pre-pivot/*.sh`
   scripts to run before latter initramfs cleanups

`/lib/dracut/hooks/cleanup/*.sh`
   scripts to run before the real init is executed and the initramfs
   disappears
   All processes started before should be killed here.


## Testsuite

### Rootless in a container with podman

```console
$ cd <DRACUT_SOURCE>
$ podman pull [CONTAINER]
$ podman run --rm -it \
    --cap-add=SYS_PTRACE --user 0 \
    -v /dev:/dev -v ./:/dracut:z \
    [CONTAINER] \
    bash -l
# cd /dracut
# ./configure
# make -j $(getconf _NPROCESSORS_ONLN)
# cd test
# make V=1 SKIP="16 60 61" clean check
```

with `[CONTAINER]` being one of the
[github `dracutdevs` containers](https://github.com/orgs/dracutdevs/packages),
e.g. `ghcr.io/dracutdevs/fedora:latest`.

### On bare metal

For the testsuite to pass, you will have to install at least the software packages
mentioned in the `test/container` Dockerfiles.

```
$ sudo make clean check
```

in verbose mode:
```
$ sudo make V=1 clean check
```

only specific test:
```
$ sudo make TESTS="01 20 40" clean check
```
only runs the 01, 20 and 40 tests.

debug a specific test case:
```
$ cd TEST-01-BASIC
$ sudo make clean setup run
```
... change some kernel parameters in `test.sh` ...
```
$ sudo make run
```
to run the test without doing the setup.
