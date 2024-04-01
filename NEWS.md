[Rendered view](https://github.com/dracutdevs/dracut/blob/master/NEWS.md)

dracut-050
==========

#### Features

* **systemd:**  install systemd-executor ([bee1c482](https://github.com/dracutdevs/dracut/commit/bee1c4824a8cd47ce6c01892a548bdc07b1fa678))

#### Bug Fixes

* **dracut-initramfs-restore.sh:**  do not set selinux labels if disabled ([4d594210](https://github.com/dracutdevs/dracut/commit/4d594210d6ef4f04a9dbadacea73e9461ded352d))
* **install.d:**  do not create initramfs if the supplied image is UKI ([b2af8c8b](https://github.com/dracutdevs/dracut/commit/b2af8c8bcfc72802e02e2c0adc2eed9279101624))
* **overlayfs:**  split overlayfs mount in two steps ([bddffeda](https://github.com/dracutdevs/dracut/commit/bddffedae038ceca263a904e40513a6e92f1b558))
* **pkcs11:**  delete trailing dot on libcryptsetup-token-systemd-pkcs11.so ([1c762c0d](https://github.com/dracutdevs/dracut/commit/1c762c0da6ed2bb6fa44d5e0968605cc4d45361c))
* **systemd-journald:**  add systemd-sysusers dependency ([4971f443](https://github.com/dracutdevs/dracut/commit/4971f443726360216a4ef3ba8baea258a1cd0f3b))
* **systemd-repart:**  correct undefined $libdir ([1586af09](https://github.com/dracutdevs/dracut/commit/1586af098fb17f7565d1699953e4e4b536304089))

#### Contributors

- Harald Hoyer <harald@profian.com>
- Antonio Alvarez Feijoo <antonio.feijoo@suse.com>
- Jóhann B. Guðmundsson <johannbg@gmail.com>
- Laszlo Gombos <laszlo.gombos@gmail.com>
- Kairui Song <kasong@redhat.com>
- Daniel Molkentin <daniel.molkentin@suse.com>
- Martin Wilck <mwilck@suse.de>
- Henrik Gombos <henrik99999@gmail.com>
- Lubomir Rintel <lkundrak@v3.sk>
- Lukas Nykryn <lnykryn@redhat.com>
- Beniamino Galvani <bgalvani@redhat.com>
- наб <nabijaczleweli@nabijaczleweli.xyz>
- Jonathan Lebon <jonathan@jlebon.com>
- David Tardon <dtardon@redhat.com>
- Frantisek Sumsal <frantisek@sumsal.cz>
- David Disseldorp <ddiss@suse.de>
- Pavel Valena <pvalena@redhat.com>
- Benjamin Drung <benjamin.drung@canonical.com>
- Thomas Blume <thomas.blume@suse.com>
- Renaud Métrich <rmetrich@redhat.com>
- Zoltán Böszörményi <zboszor@pr.hu>
- Marcos Mello <marcosfrm@gmail.com>
- Shreenidhi Shedi <sshedi@vmware.com>
- David Teigland <teigland@redhat.com>
- Dusty Mabe <dusty@dustymabe.com>
- Frederick Grose <fgrose@sugarlabs.org>
- Kairui Song <kasong@tencent.com>
- Adrien Thierry <athierry@redhat.com>
- Alexander Tsoy <alexander@tsoy.me>
- Böszörményi Zoltán <zboszor@pr.hu>
- Mikhail Novosyolov <m.novosyolov@rosalinux.ru>
- Tao Liu <ltao@redhat.com>
- Tomasz Paweł Gajc <tpgxyz@gmail.com>
- Hannes Reinecke <hare@suse.com>
- Jonas Witschel <diabonas@gmx.de>
- Nathan Rini <nate@ucar.edu>
- Đoàn Trần Công Danh <congdanhqx@gmail.com>
- Jan Macku <jamacku@redhat.com>
- Nicolas Chauvet <kwizart@gmail.com>
- q66 <daniel@octaforge.org>
- Andrew Ammerlaan <andrewammerlaan@gentoo.org>
- Colin Walters <walters@verbum.org>
- Masahiro Matsuya <mmatsuya@redhat.com>
- Mike Gilbert <floppym@gentoo.org>
- Norbert Lange <norbert.lange@andritz.com>
- Peter Robinson <pbrobinson@fedoraproject.org>
- Takashi Iwai <tiwai@suse.de>
- Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl>
- Zoltán Böszörményi <zboszor@gmail.com>
- Brian C. Lane <bcl@redhat.com>
- Doan Tran Cong Danh <congdanhqx@gmail.com>
- Gaël PORTAY <gael.portay@collabora.com>
- Jiri Konecny <jkonecny@redhat.com>
- Matt Coleman <matt@datto.com>
- Max Resch <resch.max@gmail.com>
- Stefan Berger <stefanb@linux.ibm.com>
- Topi Miettinen <toiwoton@gmail.com>
- dependabot[bot] <49699333+dependabot[bot]@users.noreply.github.com>
- keentux <valentin.lefebvre@suse.com>
- Alberto Planas <aplanas@suse.com>
- Alexander Wenzel <alexander.wenzel@qbeyond.de>
- Alexey Shabalin <shaba@altlinux.org>
- Andre Russ <andre.russ@sap.com>
- Andreas Schwab <schwab@suse.de>
- Coiby Xu <coxu@redhat.com>
- Cornelius Hoffmann <coding@hoffmn.de>
- Daniel Cordero <dracut@0xdc.io>
- German Maglione <gmaglione@redhat.com>
- Hari Bathini <hbathini@linux.ibm.com>
- Javier Martinez Canillas <javierm@redhat.com>
- José María Fernández <josemariafg@gmail.com>
- Lee Duncan <lduncan@suse.com>
- LinkTed <link.ted@mailbox.org>
- Luiz Angelo Daros de Luca <luizluca@gmail.com>
- Mariusz Tkaczyk <mariusz.tkaczyk@linux.intel.com>
- Michal Koutný <mkoutny@suse.com>
- Nicolas Porcel <nicolasporcel06@gmail.com>
- Patrick Talbert <ptalbert@redhat.com>
- Pedro Monreal <pmgdeb@gmail.com>
- Petr Pavlu <petr.pavlu@suse.com>
- Pingfan Liu <piliu@redhat.com>
- Tianhao Chai <cth451@gmail.com>
- Tony Asleson <tasleson@redhat.com>
- nkraetzschmar <nkraetzschmar@users.noreply.github.com>
- Érico Rolim <erico.erc@gmail.com>
- “Masahiro <mmatsuya@redhat.com>
- 0x5c <dev@0x5c.io>
- A. Wilcox <AWilcox@Wilcox-Tech.com>
- Adam Alves <adamoa@gmail.com>
- Adam Williamson <awilliam@redhat.com>
- Alexander Miroshnichenko <alex@millerson.name>
- Alexander Sosedkin <asosedkin@redhat.com>
- Alexey Kodanev <alexey.kodanev@oracle.com>
- Andrew Halaney <ahalaney@redhat.com>
- Andrew J. Hesford <ajh@sideband.org>
- Andrey Sokolov <keremet@altlinux.org>
- Anjali Kulkarni <anjali.k.kulkarni@oracle.com>
- Antz <antzz@protonmail.ch>
- Arnaud Rebillout <arnaud.rebillout@collabora.com>
- Attila Bruncsak <bruncsak@users.noreply.github.com>
- Ben Howard <ben.howard@redhat.com>
- Benjamin Gilbert <bgilbert@redhat.com>
- Benjamin Marzinski <bmarzins@redhat.com>
- Brandon Sloane <btsloane@verizon.net>
- Bruno E. O. Meneguele <bmeneg@redhat.com>
- Charles Rose <charles.rose@dell.com>
- Cole Robinson <crobinso@redhat.com>
- Conrad Hoffmann <ch@bitfehler.net>
- Daan De Meyer <daan.j.demeyer@gmail.com>
- Dan Horák <dhorak@redhat.com>
- Daniel McIlvaney <damcilva@microsoft.com>
- Daniel P. Berrangé <berrange@redhat.com>
- David Cassany <dcassany@suse.com>
- David Hildenbrand <david@redhat.com>
- Denis Volkov <denis@simpletexting.net>
- Derek Hageman <hageman@inthat.cloud>
- Dirk Müller <dirk@dmllr.de>
- Dmitry Klochkov <dmitry.klochkov@bell-sw.com>
- Donovan Tremura <neurognostic@protonmail.ch>
- Emanuele Giuseppe Esposito <eesposit@redhat.com>
- Enzo Matsumiya <ematsumiya@suse.de>
- Eugene S. Sobolev <sobolev@protei.ru>
- Evgeni Golov <evgeni@golov.de>
- Fabian Vogt <fvogt@suse.de>
- Frank Deng <frank.deng@oracle.com>
- Frederick Grose <4335897+FGrose@users.noreply.github.com>
- Glenn Morris <rgm@stanford.edu>
- GuoChuang <guo.chuang@zte.com.cn>
- Hans de Goede <hdegoede@redhat.com>
- Hongxu Jia <hongxu.jia@windriver.com>
- Jacob Wen <jian.w.wen@oracle.com>
- James Morris <morisja@gmail.com>
- Jaroslav Jindrak <dzejrou@gmail.com>
- Jens Heise <46450477+heisej@users.noreply.github.com>
- Jeremy Linton <jlinton@redhat.com>
- John Meneghini <jmeneghi@redhat.com>
- Jonas Jelten <jj@sft.lol>
- Jonas Witschel <diabonas@archlinux.org>
- Kenneth D'souza <kennethdsouza94@gmail.com>
- Khem Raj <raj.khem@gmail.com>
- Lars Wendler <polynomial-c@gentoo.org>
- Laura Hild <lsh@jlab.org>
- Lennart Poettering <lennart@poettering.net>
- Lev Veyde <lveyde@redhat.com>
- Lianbo Jiang <lijiang@redhat.com>
- Luca BRUNO <luca.bruno@coreos.com>
- Lucas C. Villa Real <lucasvr@gmail.com>
- Marek Marczykowski-Górecki <marmarek@invisiblethingslab.com>
- Marko Myllynen <myllynen@redhat.com>
- Matthew Thode <mthode@mthode.org>
- Matthias Berndt <matthias_berndt@gmx.de>
- Michal Hecko <mhecko@redhat.com>
- Michał Zegan <webczat@outlook.com>
- Morten Linderud <morten@linderud.pw>
- Neal Gompa <neal@gompa.dev>
- Nicolas Saenz Julienne <nsaenzjulienne@suse.de>
- Ondrej Dubaj <odubaj@redhat.com>
- Ondrej Mosnacek <omosnace@redhat.com>
- Paul Robins <exp@users.noreply.github.com>
- Peter Georg <peter.georg@physik.uni-regensburg.de>
- Peter Levine <plevine457@gmail.com>
- Petr Tesarik <ptesarik@suse.com>
- Petr Vorel <pvorel@suse.cz>
- Radek Vykydal <rvykydal@redhat.com>
- Rumbaut Thomas <Thomas.Rumbaut@digipolis.gent>
- Sam James <sam@gentoo.org>
- Savyasachee Jha <genghizkhan91@hawkradius.com>
- Scott Moser <smoser@brickies.net>
- Sebastian Mitterle <smitterl@redhat.com>
- Sergei Iudin <tsipa740@gmail.com>
- Sergio E. Nemirowski <sergio@outerface.net>
- Thierry Vignaud <thierry.vignaud@gmail.com>
- Thomas Abraham <tabraham@suse.com>
- Thomas Haller <thaller@redhat.com>
- Valentin Lefebvre <valentin.lefebvre@suse.com>
- Vitaly Kuznetsov <vkuznets@redhat.com>
- Vladius25 <vkorol2509@icloud.com>
- Wenchao Hao <haowenchao@huawei.com>
- Yang Liu <50459973+ly4096x@users.noreply.github.com>
- foopub <45460217+foopub@users.noreply.github.com>
- gaoyi <ymuemc@163.com>
- gombi <gombi@>
- innovara <fombuena@outlook.com>
- jbash aka John Bashinski <jbash@velvet.com>
- joamonwx <unknown>
- joshuacov1 <joshuacov@gmail.com>
- lapseofreason <lapseofreason0@gmail.com>
- leo-lb <lle-bout@zaclys.net>
- lilinjie <lilinjie@uniontech.com>
- logan <logancaldwell23@gmail.com>
- masem <matej.semian@gmail.com>
- mulhern <amulhern@redhat.com>
- mwberry <mwberry@users.noreply.github.com>
- nabijaczleweli <nabijaczleweli@gmail.com>
- realtime-neil <neil@rtr.ai>
- runsisi <runsisi@hust.edu.cn>
- tupper <tupper.bob@gmail.com>
- Дамјан Георгиевски <gdamjan@gmail.com>

dracut-060
==========

#### Performance

* **dracut-install:**
  *  don't strdup() environment block ([efd4ca27](https://github.com/dracutdevs/dracut/commit/efd4ca271f15530d7264d2c87a104284e20b28aa))
  *  don't reallocate {src,dst}path in hmac_install() ([77226cb4](https://github.com/dracutdevs/dracut/commit/77226cb412822dc7614037c6d9225d98e64d4a55))
  *  don't strdup() excessively for dracut_install() ([a20556f0](https://github.com/dracutdevs/dracut/commit/a20556f0e51249e501aeb87eb5a337a15db52253))
  *  stat() w/unused buf -> access(F_OK) in dracut-install ([e7ed8337](https://github.com/dracutdevs/dracut/commit/e7ed8337bb9fec0283af5dc745450394ba649a03))
  *  multiple single-character strstr()s -> strpbrk() ([751a110f](https://github.com/dracutdevs/dracut/commit/751a110f29f07cb41246c09784c63bb26bb708c6))

#### Bug Fixes

*   codespell ([ddf63231](https://github.com/dracutdevs/dracut/commit/ddf6323145d50d33a897687474c73770328bf757))
*   make iso-scan trigger udev events ([7b530f26](https://github.com/dracutdevs/dracut/commit/7b530f26368d723dcc34fb67d687c60009b06412), closes [#2183](https://github.com/dracutdevs/dracut/issues/2183))
*   shellcheck 0.8.0 ([88fe9205](https://github.com/dracutdevs/dracut/commit/88fe9205de49c12ed8eaac2ca227a72830750955))
*   shellcheck 0.8.0 ([08b63a25](https://github.com/dracutdevs/dracut/commit/08b63a25296d689186c6343f96e764bf893367cb))
* **99base:**  adjust to allow mksh as initrd shell ([a0d14d3b](https://github.com/dracutdevs/dracut/commit/a0d14d3bc691b318507c01708bc67d9e3b9d5109))
* **Makefile:**
  *  remove leftover rpm build rules ([f5cc202e](https://github.com/dracutdevs/dracut/commit/f5cc202e998eb22bda98920b8eeeb0f027ca0b6e))
  *  no longer upload to kernel.org ([ffc766d2](https://github.com/dracutdevs/dracut/commit/ffc766d23d9175673f722a3c81e7609496167845))
  *  execute command -v instead of which ([4235c035](https://github.com/dracutdevs/dracut/commit/4235c035ff1abad0c22125c26cab813c42b29da0))
* **base:**  do not quote $CLINE in the `set` command ([8b951d20](https://github.com/dracutdevs/dracut/commit/8b951d20d409b3647c85a9c6d064ccb15cdb5fe7))
* **bluetooth:**
  *  make bluetooth rules more strict ([dfa408c9](https://github.com/dracutdevs/dracut/commit/dfa408c9de7cd0b0af6099b6f1e0cce2e70ec467))
  *  add missing files ([e84d65c5](https://github.com/dracutdevs/dracut/commit/e84d65c5b0191582e26fe9cc150d460652b34b33))
  *  include it if Appearance matches the value assigned for keyboard ([8079ceaf](https://github.com/dracutdevs/dracut/commit/8079ceafcac910d0c061830769866710c3e889a8))
  *  warn user instead of including it by default ([0ecb0388](https://github.com/dracutdevs/dracut/commit/0ecb038832038523a27f989d0eb82b45fb67861c))
* **btrfs:**
  *  do not require module via cmdline when --no-kernel ([7ed765dd](https://github.com/dracutdevs/dracut/commit/7ed765dd23e4c5616c82d1cbf8b4dbceaafc7647))
  *  add missing cmdline function ([2b47a2ef](https://github.com/dracutdevs/dracut/commit/2b47a2efe91ab8be480925c04388200a3666812c))
* **crypt:**  add missing libraries ([c5dca3d6](https://github.com/dracutdevs/dracut/commit/c5dca3d68915cef077fda2bc5292e12f82cf6dd6))
* **crypt-gpg:**  do not use always --card-status ([e3e8108e](https://github.com/dracutdevs/dracut/commit/e3e8108eb75247249ec05eaba943c3f48637c04b))
* **dmsquash-live:**
  *  allow other fstypes ([4000a1ec](https://github.com/dracutdevs/dracut/commit/4000a1ecff208479254be8ce88de826099e2b685))
  *  restore compatibility with earlier releases ([0e780720](https://github.com/dracutdevs/dracut/commit/0e780720efe6488c4e07af39926575ee12f40339))
  *  live:/dev/* ([93339444](https://github.com/dracutdevs/dracut/commit/93339444361303c15e26b6ff5cea6ef99ad0b3e0))
* **dmsquash-live-autooverlay:**  specify filesystemtype when it is already known ([179e1a99](https://github.com/dracutdevs/dracut/commit/179e1a992fc2b74d55a600bef152d5df43802104))
* **dracut-functions:**  avoid calling grep with PCRE (-P) ([67591e88](https://github.com/dracutdevs/dracut/commit/67591e8855006eb02aa0ffab7349ab770e471473))
* **dracut-functions.sh:**  convert mmcblk to the real kernel module name ([a62e895d](https://github.com/dracutdevs/dracut/commit/a62e895db9510f0fc4c47ee81b1436096eca4d64))
* **dracut-init.sh:**
  *  `module_check` method ignores `forced` option ([6c9f403f](https://github.com/dracutdevs/dracut/commit/6c9f403f1c219b8e2ff62011bfcc1b5e254b411a))
  *  use the local _ret variable ([1b53bb62](https://github.com/dracutdevs/dracut/commit/1b53bb6297d83940b52e806c01030e8f5035d9f2))
  *  correct check in `is_qemu_virtualized` function ([3e2f685e](https://github.com/dracutdevs/dracut/commit/3e2f685ecb4a968d5cd889803d5a248dab89473a))
  *  correct typo in comment ([1aafcab9](https://github.com/dracutdevs/dracut/commit/1aafcab935b7e84cea8fc3f084b6935f87b2b8a5))
* **dracut-initramfs-restore.sh:**  handle /etc/machine-id empty or uninitialized ([260883d9](https://github.com/dracutdevs/dracut/commit/260883d96f33e7aced3d00c85d0ebffcec1385a1))
* **dracut-install:**
  *  protect against broken links pointing to themselves ([32f6f364](https://github.com/dracutdevs/dracut/commit/32f6f364ddeb706bf8741f2895d60022aee264e7))
  *  prevent possible infinite recursion with suppliers ([131822e2](https://github.com/dracutdevs/dracut/commit/131822e26d76a3ce2028e9a545be2af066805629))
  *  continue parsing if ldd prints "cannot execute binary file" ([9a531ca0](https://github.com/dracutdevs/dracut/commit/9a531ca044e3cfe9b670e7e4d59a7bae5bafec1e))
* **dracut-lib.sh:**  remove successful finished initqueue scripts ([07af8d58](https://github.com/dracutdevs/dracut/commit/07af8d58745a121052cab49c70a476f02996da1e))
* **dracut-systemd:**
  *  rootfs-generator cannot write outside of generator dir ([86c8a5a7](https://github.com/dracutdevs/dracut/commit/86c8a5a7c2573645e67537fb9975efab808d42c9))
  *  check and create generator dir outside of inner function ([acfa793b](https://github.com/dracutdevs/dracut/commit/acfa793b5cc035ebd36b0c5ce97ba2fd89e5745c))
  *  do not hardcode the systemd generator directory ([a7c04716](https://github.com/dracutdevs/dracut/commit/a7c04716a5e528d86135bf87745054f7cbd54469))
  *  remove unused argument ([eb75861c](https://github.com/dracutdevs/dracut/commit/eb75861c2a1c05eb142616da1891a7fa5a2a34e1))
* **dracut.sh:**
  *  remove microcode check based on CONFIG_MICROCODE_[AMD|INTEL] ([6c80408c](https://github.com/dracutdevs/dracut/commit/6c80408c8644a0add1907b0593eb83f90d6247b1))
  *  exit if resolving executable dependencies fails ([b2c6b584](https://github.com/dracutdevs/dracut/commit/b2c6b584e2227e68f54c8843925dcb73aefe87ac))
  *  shellcheck warning SC1004 ([dbdab2d8](https://github.com/dracutdevs/dracut/commit/dbdab2d87fa49c7fdd08b274d8a21e6046360cad))
  *  use gawk for strtonum ([33a66ed0](https://github.com/dracutdevs/dracut/commit/33a66ed04bdc30eccb172a0cd6dcc36d9d74f825))
  *  also prevent fsfreeze for tmpfs ([09d3ec16](https://github.com/dracutdevs/dracut/commit/09d3ec1648822d84e95b274b60cb51b80e8f49f9))
  *  correct path for UEFI stub on split-usr systems ([c1588995](https://github.com/dracutdevs/dracut/commit/c1588995ae0d9f984ad08f2d466f7a09646c6517))
  *  silence the output of hardlinking files by default ([2a26eec5](https://github.com/dracutdevs/dracut/commit/2a26eec5cc1f384f71226066f13db89f92913f28))
  *  handle imagebase for uefi ([6178a9d8](https://github.com/dracutdevs/dracut/commit/6178a9d83ffad67fa371cef2ff3f5bbb337bc8b7))
  *  handle /etc/machine-id empty or uninitialized ([97fe0976](https://github.com/dracutdevs/dracut/commit/97fe09769d6a86492c39e0368f088f54f7c0fa6e))
  *  use dynamically uefi's sections offset ([f32e95bc](https://github.com/dracutdevs/dracut/commit/f32e95bcadbc5158843530407adc1e7b700561b1))
  *  kmoddir does not handle trailing / ([1ddcb137](https://github.com/dracutdevs/dracut/commit/1ddcb137ea2a4d79491ff94f1f7802dcaa7ac381))
  *  handle sbsign errors for UEFI builds ([a6dd5bfb](https://github.com/dracutdevs/dracut/commit/a6dd5bfb9a514a3bf650cc1e8d4311c05e9b968c))
  *  handle out of space error for UEFI builds ([8602df70](https://github.com/dracutdevs/dracut/commit/8602df705879100be17e93fe56f5cbeb6216248f))
  *  --sysroot option broken if global variables not set in conf ([6f4a5c90](https://github.com/dracutdevs/dracut/commit/6f4a5c90ab993d2559720c2d4023d99ad43df00a))
  *  correct --help and --version exit codes ([cda6b00a](https://github.com/dracutdevs/dracut/commit/cda6b00abce0e68e353ab929b86cfaf45c3dc1c8))
* **fido2:**  libfido2.so depends on libz.so ([15970768](https://github.com/dracutdevs/dracut/commit/1597076887c6744b9ec69c0ac44a1134fd700700))
* **fips:**
  *  move fips-boot script to pre-pivot ([d777dd3d](https://github.com/dracutdevs/dracut/commit/d777dd3dab50c2e383c00751fae5d9593339315f))
  *  only unmount /boot if it was mounted by the fips module ([ab26ad2c](https://github.com/dracutdevs/dracut/commit/ab26ad2c2ab4a5884e392951998d40829f130387))
  *  do not blindly remove /boot ([1fabbb64](https://github.com/dracutdevs/dracut/commit/1fabbb6412b70bdd1aac5279b90b9a23a267ffc5))
* **fs-lib:**  remove quoting form the first argument of the e2fsck call ([9aa332ca](https://github.com/dracutdevs/dracut/commit/9aa332cad7196b6e05b9e2f1810dc54bb38ed2ac))
* **github:**  exempt issues in a milestone ([c8a703aa](https://github.com/dracutdevs/dracut/commit/c8a703aaa7bbfe4f078fef5a4318243db059b87b))
* **install:**  do not undef _FILE_OFFSET_BITS ([70aeb4c1](https://github.com/dracutdevs/dracut/commit/70aeb4c1a56027bc2fe5570c080d96625b377c94))
* **install.d:**
  *  do not create initramfs if the supplied image is UKI ([b2af8c8b](https://github.com/dracutdevs/dracut/commit/b2af8c8bcfc72802e02e2c0adc2eed9279101624))
  *  respect even more kernel-install vars, plus style fixes ([17b8649e](https://github.com/dracutdevs/dracut/commit/17b8649eb931f3f4990ac8184fe23fc257df6fa5))
  *  respect more kernel-install env variables ([a037634a](https://github.com/dracutdevs/dracut/commit/a037634ad71711d29828214830ebdade0c449dbc))
* **integrity:**  do not require ls ([a804945f](https://github.com/dracutdevs/dracut/commit/a804945f27a0ccc2f69ae694599b1afec2afe8b1))
* **iscsi:**
  *  prefix syntax for static iBFT IPv6 addresses ([c3b65a49](https://github.com/dracutdevs/dracut/commit/c3b65a493a635a3f85f9e65c4337cd4c144ff8fc))
  *  install 8021q module unconditionally ([aa5d9526](https://github.com/dracutdevs/dracut/commit/aa5d9526eca23f642fd623d2c857fd8f9930b83d))
* **kernel-modules:**
  *  add interconnect drivers ([afb5717e](https://github.com/dracutdevs/dracut/commit/afb5717e67727d49fae0d2a1a4169e5b247387f4))
  *  add UFS drivers ([89269d23](https://github.com/dracutdevs/dracut/commit/89269d239f0539b7bd4339ba98a0d1b188b59962))
  *  use modalias info in get_dev_module() ([87a76dbb](https://github.com/dracutdevs/dracut/commit/87a76dbb578aff473e690857d1b714eacd92b9ec))
* **load_fstype:**  avoid false positive searchs ([10cf8e46](https://github.com/dracutdevs/dracut/commit/10cf8e46f43a7a2094e4d861c1296db6af0e0fa1))
* **lsinitrd.sh:**
  *  handle /etc/machine-id empty or uninitialized ([971b302d](https://github.com/dracutdevs/dracut/commit/971b302d70fbbfac3b6047654b7dc7ceeb1c17e7))
  *  handle filenames with special characters ([1f84ff88](https://github.com/dracutdevs/dracut/commit/1f84ff882fe272ef0185a284eee82e89735c833d))
* **lvmthinpool-monitor:**  activate lvm thin pool before extend its size ([e9b47742](https://github.com/dracutdevs/dracut/commit/e9b4774239989257999053033fc92cded7803896))
* **man:**
  *  add missing initrd-root-device.target to flow chart ([f11e8fff](https://github.com/dracutdevs/dracut/commit/f11e8fffc2db1f6f02d09207a1edbf1d898249d7))
  *  remove duplicate entry ([6af3fcfd](https://github.com/dracutdevs/dracut/commit/6af3fcfd7f699ec4bb3f1e9ac71b7a9ebb9804b3))
* **modsign:**  load keys to correct keyring ([b7ef1302](https://github.com/dracutdevs/dracut/commit/b7ef1302715bead649625666f92eff434082de1f))
* **multipath:**  remove dependency on multipathd.socket ([297525c5](https://github.com/dracutdevs/dracut/commit/297525c5c0781e13c4bf86aa42e81b9f166802ad))
* **network:**
  *  IPv6: don't wait for RA for static IPv6 assignments ([726d56ca](https://github.com/dracutdevs/dracut/commit/726d56ca0a23e5a39de5f809da2d20ce7985d437))
  *  don't assume prefix length 64 by default ([7ff255a4](https://github.com/dracutdevs/dracut/commit/7ff255a4488f63cf84179d4572f44fe3a1bd29ec))
* **network,dbus:**  improve dependency checking ([3f8f115a](https://github.com/dracutdevs/dracut/commit/3f8f115a27b2bb63f0893262b6c951a187bac8ef))
* **network-legacy:**
  *  typo ([e2f961a2](https://github.com/dracutdevs/dracut/commit/e2f961a2bd7b5f5cbff6394d6be6eace15e236b7))
  *  always include af_packet ([b074216b](https://github.com/dracutdevs/dracut/commit/b074216be93dc4512b76fcd6b77a727aef11b22b))
* **network-manager:**  add "After" dependency on dbus.service ([d8a9a73d](https://github.com/dracutdevs/dracut/commit/d8a9a73df9688989b5e47469e74ad5aa666a5bfb))
* **nvmf:**
  *  support /etc/nvme/config.json ([f07117d6](https://github.com/dracutdevs/dracut/commit/f07117d68d07d52aa4ce8b4b2549a0cb716b7f4b))
  *  install 8021q module unconditionally ([902f3a8f](https://github.com/dracutdevs/dracut/commit/902f3a8f84643e4249b9bbb2e81d1b13eaf35364))
* **plymouth:**  remove /etc/system-release dependency ([d6cef3f2](https://github.com/dracutdevs/dracut/commit/d6cef3f28e15a834284786c79f108b7c42481f96))
* **release:**  maintain dracut-version.sh in the source tree ([b4e23ce4](https://github.com/dracutdevs/dracut/commit/b4e23ce4238821b0c2dd3c846da45f9cfeb57954))
* **resolve-deps:**  check the existing file—not the source ([5ac581ef](https://github.com/dracutdevs/dracut/commit/5ac581ef66dd8f1939e771419824137aebbc8f66))
* **systemd:**
  *  add new systemd-tmpfiles-setup-dev-early.service ([7528d84d](https://github.com/dracutdevs/dracut/commit/7528d84de84d9c1fb7d5f54712c692600e21b044))
  *  do not include systemd-random-seed.service ([925febf8](https://github.com/dracutdevs/dracut/commit/925febf89d54c0bef9e3c8fda3b8e5b1f8ba30cd))
* **systemd-ac-power:**  correct systemd-ac-power binary path ([df2458a6](https://github.com/dracutdevs/dracut/commit/df2458a6b8aec70e74757ea7ae35f672a99ddc17))
* **systemd-journald:**  do not include systemd-journal-flush.service ([eff2a939](https://github.com/dracutdevs/dracut/commit/eff2a9398120b29fd869eec991410e254d0dcbb8))
* **systemd-networkd:**
  *  correct typos in override paths ([f0dc7ec9](https://github.com/dracutdevs/dracut/commit/f0dc7ec96b81fec100a5ab948c12846b2b9910e6))
  *  add missing conf files and services ([71e391eb](https://github.com/dracutdevs/dracut/commit/71e391ebdc8f5d88447db1b6d475c813d82d5ffb))
* **systemd-pcrphase:**  only include systemd-pcrphase-initrd.service ([cd6f683d](https://github.com/dracutdevs/dracut/commit/cd6f683d634970112a29867137431d0d57f8c957))
* **systemd-resolved:**  correct typo in override path ([2d083021](https://github.com/dracutdevs/dracut/commit/2d083021910f0633035a056e0541549efffec896))
* **systemd-timedated:**  correct typo in override path ([765e69ce](https://github.com/dracutdevs/dracut/commit/765e69ce4d88a4ef6c1028cc117b3f233a285f0e))
* **systemd-tmpfiles:**  do not include systemd-tmpfiles-clean.timer ([1ef00735](https://github.com/dracutdevs/dracut/commit/1ef00735ae4fa19684598a8f7868e8b36b6bf5fe))
* **systemd-udevd:**  add missing override paths ([570b9d40](https://github.com/dracutdevs/dracut/commit/570b9d405116c9763266aa2e88ea0a2460c734ba))
* **test:**
  *  only use QEMU machine q35 on x86 ([f29e428b](https://github.com/dracutdevs/dracut/commit/f29e428bdb3068e25150bc9591a961bd2df66442))
  *  use bash for jobs -r parameter ([9a18f133](https://github.com/dracutdevs/dracut/commit/9a18f1335fcab1eb84fedc45e450851d093335aa))
  *  rename test 60 ([3d7c0ffb](https://github.com/dracutdevs/dracut/commit/3d7c0ffbd65c8d5c9fef559a51a2405a28c6f6a0))
  *  improve test 60 ([5e846cb1](https://github.com/dracutdevs/dracut/commit/5e846cb1320e32db1e3d200743f8fc08732d4c9e))
  *  remove leftover link file from server rootfs ([8f44740f](https://github.com/dracutdevs/dracut/commit/8f44740f2c234ddb275e0a11e23d45e3678eb4a0))
  *  assign fixed address to bridge ([9fb64d96](https://github.com/dracutdevs/dracut/commit/9fb64d96ab7a7e19a7940e56e9bc0da863b46386))
  *  bump DHCP timeout to 30 seconds ([462d9b92](https://github.com/dracutdevs/dracut/commit/462d9b9254d4386e9eac267547ee4e8cd2487c3d))
  *  remove check on dhclient support for --timeout ([da959483](https://github.com/dracutdevs/dracut/commit/da959483333c6ab83e4cdef837130eacec6b35d7))
  *  adapt multinic test for new NetworkManager versions ([d3993c7d](https://github.com/dracutdevs/dracut/commit/d3993c7dabdd37c54a991c6ad9ea38365598d16a))
* **udev-rules:**
  *  remove firmware.rules ([7310a641](https://github.com/dracutdevs/dracut/commit/7310a641e227aae446684baeb48f878c3299ff9f))
  *  remove old eudev specific rule ([6d554d9b](https://github.com/dracutdevs/dracut/commit/6d554d9b98333372aeb20fd153a42c8171979825))
  *  remove old redhat specific rule ([d648bf80](https://github.com/dracutdevs/dracut/commit/d648bf805a27cbf1920f0437606c9ffb2684ec18))
  *  remove old edd_id extra rules ([6a33e677](https://github.com/dracutdevs/dracut/commit/6a33e677aca49dd81826949b61acb945d672ba84))
  *  remove old debian specific rules ([1edc41af](https://github.com/dracutdevs/dracut/commit/1edc41af979e1c1097be082c357f7a4895fbbad2))
* **url-lib.sh:**  nfs_already_mounted() with trailing slash in nfs path ([966b6cec](https://github.com/dracutdevs/dracut/commit/966b6cec1bebd91ddd0f85c357f7ab57d3213f51))
* **virtiofs:**  add virtio_pci kernel module to virtiofs ([07b49a3e](https://github.com/dracutdevs/dracut/commit/07b49a3ed79a792cede7e6ee21be29aba07168bc))

#### Features

* **Makefile:**  allow setting dracut version via environment variables ([31c4d284](https://github.com/dracutdevs/dracut/commit/31c4d284017044b72ddea767c4d35d6d70473984))
* **dracut:**
  *  add --sbat option to add sbat policy to UKI ([fffeaded](https://github.com/dracutdevs/dracut/commit/fffeadedf2170563cb7c0e0cb06994b0878ed455))
  *  use log level indicator in console output ([ae88e029](https://github.com/dracutdevs/dracut/commit/ae88e029c6ad20248d229bebd7e8f10d3d094988))
* **dracut-init.sh:**
  *  do not print by default if an udev rule is skipped ([aa20bbb5](https://github.com/dracutdevs/dracut/commit/aa20bbb5b1c78963331fb6261763ea4c51ebc04f))
  *  specify if a module cannot be found or cannot be installed ([a10078a5](https://github.com/dracutdevs/dracut/commit/a10078a5c3ce9adf309962634e71ae6e186f2621))
* **dracut-install:**  add fw_devlink suppliers as module dependencies ([3de4c731](https://github.com/dracutdevs/dracut/commit/3de4c7313260fb600507c9b87f780390b874c870))
* **fips:**  add progress messages ([68d0653e](https://github.com/dracutdevs/dracut/commit/68d0653e35f79e78b75a71c122c091ba4f4d5759))
* **install.d:**  allow using dracut in combination with ukify ([16645633](https://github.com/dracutdevs/dracut/commit/166456331d55cdc23946c11315dc2c88aab15911))
* **kernel-modules:**  driver support for macbook keyboards ([df381b7e](https://github.com/dracutdevs/dracut/commit/df381b7e0cd95f78e40ac70f0f3c96a2fa8dd189))
* **livenet:**  add memory size check depending on live image size ([52351cfa](https://github.com/dracutdevs/dracut/commit/52351cfa049a9594d539e6a5337d591e8039ab80))
* **lsinitrd:**  notify user on missing compressor ([1300a930](https://github.com/dracutdevs/dracut/commit/1300a930e76dbb380c7840760207296a1e58364c))
* **lvm:**  always include all drivers that LVM can use ([a109c612](https://github.com/dracutdevs/dracut/commit/a109c6123ffa8506379b73a4b1aeee4d0b67866d))
* **network-wicked:**  remove module ([9dbbebb1](https://github.com/dracutdevs/dracut/commit/9dbbebb1339d1c3dc8e6b8835a6edbc95c66e2fe))
* **nvmf:**  add code for parsing the NBFT ([b490f6f7](https://github.com/dracutdevs/dracut/commit/b490f6f7d7cf1c322b47af4e44d7f238612fb260))
* **resume:**  also consider resume= in the cmdline as enabling hibernation ([e3a7112b](https://github.com/dracutdevs/dracut/commit/e3a7112bef794e2f2dd741ec2c74fa9cb9117651), closes [#924](https://github.com/dracutdevs/dracut/issues/924))
* **systemd:**  install systemd-executor ([bee1c482](https://github.com/dracutdevs/dracut/commit/bee1c4824a8cd47ce6c01892a548bdc07b1fa678))
* **systemd-creds:**  introducing the systemd-creds module ([48c2cb45](https://github.com/dracutdevs/dracut/commit/48c2cb457b1472d09453be130797bc6e0e194f7c))
* **systemd-rfkill:**  remove module ([c4e6eaf9](https://github.com/dracutdevs/dracut/commit/c4e6eaf9c61616a2f27ef6e91cc787888afecde4))
* **test:**  nfs_fetch_url test into nfs test ([8f9ad068](https://github.com/dracutdevs/dracut/commit/8f9ad06873eb50754611ece2c18a0cd0b22336c0))

#### Contributors

- Antonio Alvarez Feijoo <antonio.feijoo@suse.com>
- Henrik Gombos <henrik99999@gmail.com>
- Laszlo Gombos <laszlo.gombos@gmail.com>
- Benjamin Drung <benjamin.drung@canonical.com>
- Beniamino Galvani <bgalvani@redhat.com>
- Martin Wilck <mwilck@suse.de>
- наб <nabijaczleweli@nabijaczleweli.xyz>
- Adrien Thierry <athierry@redhat.com>
- Frederick Grose <fgrose@sugarlabs.org>
- Andrew Ammerlaan <andrewammerlaan@gentoo.org>
- Pavel Valena <pvalena@redhat.com>
- Frantisek Sumsal <frantisek@sumsal.cz>
- Jóhann B. Guðmundsson <johannbg@gmail.com>
- Tao Liu <ltao@redhat.com>
- “Masahiro <mmatsuya@redhat.com>
- 0x5c <dev@0x5c.io>
- Andrew Halaney <ahalaney@redhat.com>
- Daniel McIlvaney <damcilva@microsoft.com>
- David Disseldorp <ddiss@suse.de>
- Dmitry Klochkov <dmitry.klochkov@bell-sw.com>
- Emanuele Giuseppe Esposito <eesposit@redhat.com>
- John Meneghini <jmeneghi@redhat.com>
- Khem Raj <raj.khem@gmail.com>
- LinkTed <link.ted@mailbox.org>
- Lubomir Rintel <lkundrak@v3.sk>
- Michal Koutný <mkoutny@suse.com>
- Michał Zegan <webczat@outlook.com>
- Mike Gilbert <floppym@gentoo.org>
- Sam James <sam@gentoo.org>
- Sergio E. Nemirowski <sergio@outerface.net>
- Thomas Blume <thomas.blume@suse.com>
- Tianhao Chai <cth451@gmail.com>
- Valentin Lefebvre <valentin.lefebvre@suse.com>
- Vitaly Kuznetsov <vkuznets@redhat.com>
- keentux <valentin.lefebvre@suse.com>
- lilinjie <lilinjie@uniontech.com>

dracut-059
==========

#### Bug Fixes

* **NEWS.md:**  add missing entries ([794ce5e3](https://github.com/dracutdevs/dracut/commit/794ce5e3ee55f1b78be32873a054aed422346f4c))

#### Contributors

- Jóhann B. Guðmundsson <johannbg@gmail.com>

dracut-058
==========

#### Bug Fixes

* **90kernel-modules:**
  *  MMC and NVMe on kernels 6.0+ ([e0d57a8f](https://github.com/dracutdevs/dracut/commit/e0d57a8f5b15847a7fbae2ed3df29ec2c5d25ec7))
  *  add (nonstandard) NVMe drivers ([415e5519](https://github.com/dracutdevs/dracut/commit/415e5519d19e24d123378710abe47a2df2b22e7b))
* **90multipath:**
  *  use RemainAfterExit=yes for multipathd-configure.service ([2334031a](https://github.com/dracutdevs/dracut/commit/2334031a890a1101c78f986681236c76ba806d91))
  *  create `/etc/multipath` only ([0940be90](https://github.com/dracutdevs/dracut/commit/0940be905843e93111e96c0d70c56389240fbc04))
* **Makefile:**  reduce the number of shell invocations ([ad7d5bc8](https://github.com/dracutdevs/dracut/commit/ad7d5bc8ea181ef805f65ae690681ebe5ba29bbe))
* **base:**
  *  do not require chroot inside initramfs ([51813371](https://github.com/dracutdevs/dracut/commit/518133714b769160448a51c512d5e152ea6332da))
  *  remove grep dependency ([240a1d34](https://github.com/dracutdevs/dracut/commit/240a1d34bd5d98fb8a7d75cd1053d8abf1c73f64))
* **dbus-broker:**  add missing sockets.target.wants/dbus.socket ([7ed04618](https://github.com/dracutdevs/dracut/commit/7ed0461810602bfbd4d5492fc9ed82f15e57fa9f))
* **dmsquash-live:**
  *  add support for NFS ([8caaad4f](https://github.com/dracutdevs/dracut/commit/8caaad4fc2d75982eb87f5ebc72a4c276986f756))
  *  check kernel for built-in squashfs drivers ([922c9e28](https://github.com/dracutdevs/dracut/commit/922c9e28ed87815cf6ae0b5ee911ff0ef616d1b0))
  *  run checkisomd5 on correct device ([c8f819e6](https://github.com/dracutdevs/dracut/commit/c8f819e6c1c38e525e4b491b4215a939ee6e00df))
* **dmsquash-live-ntfs:**  remove unnecessary command ([e78f71b9](https://github.com/dracutdevs/dracut/commit/e78f71b9da29828ee4cd8444d4841ee127ef8614))
* **dmsquash-live-root:**  check kernel for built-in `overlay` drivers ([d0cd7cd3](https://github.com/dracutdevs/dracut/commit/d0cd7cd38711b5425777c3b1595dbf4288beaa23))
* **dracut:**
  *  allow to set persistent policy based on /dev/mapper device names ([9cc7ceec](https://github.com/dracutdevs/dracut/commit/9cc7ceec1e9b4028d1a72bf51f9ea488d7ca11ac))
  *  shellcheck regression in DRACUT_INSTALL calls ([097dd367](https://github.com/dracutdevs/dracut/commit/097dd367bbd61da1577a182c535c5aacdfd07031))
  *  replace invalid lzo command with lzop for LZO compression ([b2d7561b](https://github.com/dracutdevs/dracut/commit/b2d7561b98d08c7e4018aa22dc36dc1242e50f09))
  *  typo error 'aggresive' -> 'aggressive' ([e4f1dbcc](https://github.com/dracutdevs/dracut/commit/e4f1dbcc0061113cb58e555724f76a7243788236))
* **dracut-functions.sh:**
  *  check_kernel_module should follow dracutsysrootdir ([6c42d378](https://github.com/dracutdevs/dracut/commit/6c42d378abe528ee6f10c8272080eec5f3f44acb))
  *  suppress findmnt error msg if /etc/fstab not exist ([e9ed44c8](https://github.com/dracutdevs/dracut/commit/e9ed44c8864445d85018e31064cd888c358f1daf))
* **dracut-init:**  make require_kernel_modules ignore no kernel build ([d460941b](https://github.com/dracutdevs/dracut/commit/d460941b51d0178683b9098e62ad57e43fb71011))
* **dracut-init.sh:**
  *  instmods: wrong variable name ([b12ee558](https://github.com/dracutdevs/dracut/commit/b12ee558f5660073ad26415794570188e8a427b0))
  *  add missing hostonly code in the inst_multiple function ([e2fdb30b](https://github.com/dracutdevs/dracut/commit/e2fdb30b56305aed9d3be32f394352c7c3fdbcef))
  *  correct dracut-install source path ([72b700e3](https://github.com/dracutdevs/dracut/commit/72b700e3cb8a0d74033e6e20b2435d9254b36efe))
  *  propagate the result code returned by dracut-install ([d2f6f445](https://github.com/dracutdevs/dracut/commit/d2f6f445edb5de033d52ece0e982db38ac2614e2))
* **dracut-initramfs-restore.sh:**
  *  initramfs detection not working ([481b87fa](https://github.com/dracutdevs/dracut/commit/481b87fa7a82be54663071ad9ad76c34e378ddc7))
  *  hide unpack errors ([4f20ae26](https://github.com/dracutdevs/dracut/commit/4f20ae2620a9067270fe3e5f191ada6bff7b0ec1))
* **dracut-install:**
  *  use stripped kernel module path as hash key ([2f791b40](https://github.com/dracutdevs/dracut/commit/2f791b401b287f67f2421452b5f82cdb5285a637))
  *  do not try to copy files from the root directory ([ebbcf97d](https://github.com/dracutdevs/dracut/commit/ebbcf97dc7267f47ae568909305bcb05de2876b4))
  *  correctly waitpid() for cp ([13736c50](https://github.com/dracutdevs/dracut/commit/13736c50c797d63ab75468ded17bc7935d7f1f94))
  *  convert_abs_rel: return valid path on error ([06d31617](https://github.com/dracutdevs/dracut/commit/06d316171cd5e0e86c21006f93776ba9f49087cc))
* **dracut-logger.sh:**  this fixes the dlog_init check for /dev/log ([6b592f58](https://github.com/dracutdevs/dracut/commit/6b592f581c1a5ec489acee95779867e0485770fd))
* **dracut-systemd:**  run systemctl daemon-reload after remove_hostonly_files ([e1058b07](https://github.com/dracutdevs/dracut/commit/e1058b07ea2acb1bdb2d52f778639e093b1ed8a6))
* **dracut.sh:**
  *  split drivers_dir check ([d32d221e](https://github.com/dracutdevs/dracut/commit/d32d221efd77dcc0afa1d39230f7bdc2958ffca5))
  *  use DRACUT_ARCH instead of `uname -m` ([a86aea65](https://github.com/dracutdevs/dracut/commit/a86aea65186b47ac210a3947c966311bb5371aeb))
  *  make omit-drivers option do exact match for names ([444944ab](https://github.com/dracutdevs/dracut/commit/444944ab37c2446adf07dd163225707e90aabef3))
  *  correct wrong systemd variable paths ([b9dc999f](https://github.com/dracutdevs/dracut/commit/b9dc999f87a477af53e379d7fb1053d13d6dbe88))
  *  remove duplicate "dracut:" string in logger functions ([8410ee22](https://github.com/dracutdevs/dracut/commit/8410ee22903403cd673a22692a084125c835cbe9))
  *  do not fail on irregular files ([b72d0d7f](https://github.com/dracutdevs/dracut/commit/b72d0d7f9be53c1ad04f132daf0297aff7581e9c))
* **dracut.spec:**  tpm2-tools is required for crypt module to work ([8abffe7c](https://github.com/dracutdevs/dracut/commit/8abffe7cca2e210e15c618beeffe7450be357f73))
* **drm:**  add video drivers needed on hyper-v and similar ([85149b85](https://github.com/dracutdevs/dracut/commit/85149b85961aa535a3c61d492cd3594794e5cc3f))
* **github:**  yml syntax and commit message for dependabot ([32f6dd1d](https://github.com/dracutdevs/dracut/commit/32f6dd1d5f0b7c24bda8bf950df176a0791045cb))
* **i18n:**
  *  do not fail if FONT in /etc/vconsole.conf has the file extension ([e1de5bd2](https://github.com/dracutdevs/dracut/commit/e1de5bd2d711df2c6814a3c3ab8472cdb4de9101))
  *  add required includes for keymaps ([fe8fa2b0](https://github.com/dracutdevs/dracut/commit/fe8fa2b0cadbb33e27c8dd8b5851548dcd65835c))
* **install.d:**  add --verbose if KERNEL_INSTALL_VERBOSE=1 ([846a8453](https://github.com/dracutdevs/dracut/commit/846a845375b8a9ea48741079d523e6b464950ea7))
* **integrity:**
  *  do not enable EVM if there is no key ([90585c62](https://github.com/dracutdevs/dracut/commit/90585c624af15ba0abb7f32b0c2afc2b122dd019))
  *  remove unused variable ([9d1004a4](https://github.com/dracutdevs/dracut/commit/9d1004a4e9883ecabdca478a809efb5501a1e47a))
* **iscsi:**  don't install the module if kernel doesn't support iscsi ([7917d797](https://github.com/dracutdevs/dracut/commit/7917d7976ded6384433ef8fb2ce1905f0a76358e))
* **kernel-modules:**
  *  add sysctl to initramfs to handle modprobe files ([33679fff](https://github.com/dracutdevs/dracut/commit/33679fff5deb733f9dfe8d005066ac98e107c083))
  *  always include nvmem driver on nvmem_on_arm ([bc965cd8](https://github.com/dracutdevs/dracut/commit/bc965cd8890013a6362733d217c18756134bbcdf))
* **load_fstype:**  use $1 if $2 is missing ([401158e5](https://github.com/dracutdevs/dracut/commit/401158e58c47b2e1278a47b9cd236f501cfe2732))
* **lsinitrd.sh:**
  *  add a missing path to image ([e877be69](https://github.com/dracutdevs/dracut/commit/e877be69b41199ee4384ccb6352754bb9edfbba4))
  *  correct skipcpio source path ([5eb996a9](https://github.com/dracutdevs/dracut/commit/5eb996a9936a87918a4320963a8681975ed86be4))
* **lvm:**  drop dm-eventd binary and libs from initramfs ([7d3184e4](https://github.com/dracutdevs/dracut/commit/7d3184e430823f7eee4acee87576acdcf02746c2))
* **man:**
  *  correct typo ([699e3945](https://github.com/dracutdevs/dracut/commit/699e39458962bc1a06a096f24ad86ffb87e8779e))
  *  dracut.cmdline.7: clarify "rd.nvmf.discover=fc,auto" ([a90efdd7](https://github.com/dracutdevs/dracut/commit/a90efdd704271dab6717329e88b3a1c9e850d23b))
  *  dracut.cmdline(7): correct syntax for rd.nonvmf ([4b69e63b](https://github.com/dracutdevs/dracut/commit/4b69e63b7414567a03e8da79acc2efe32e0a6a94))
  *  point man pages to github.com instead of kernel.org ([d6d55584](https://github.com/dracutdevs/dracut/commit/d6d555845e53dca0b083d59c8cedf465e6b70b71))
  *  correct typo ([7fa0094c](https://github.com/dracutdevs/dracut/commit/7fa0094c0087a827a22f30ec62f03f243b000bf3))
* **multipath:**  install multipathd.socket ([02e646fc](https://github.com/dracutdevs/dracut/commit/02e646fc7ec91e1fbaa0f2097f35781ae41da937))
* **network:**
  *  check if ip command fails ([52d14607](https://github.com/dracutdevs/dracut/commit/52d14607d18d99c0c2c3242a64561b1af6a332d1))
  *  two bugs which cause minutes long boot times ([1d6f42c8](https://github.com/dracutdevs/dracut/commit/1d6f42c8a4029380c2147018e64fb7ebc9e175e7))
  *  avoid double brackets around IPv6 address ([2c26b703](https://github.com/dracutdevs/dracut/commit/2c26b703223bb65822954264bcd6ca7934c98b4a))
  *  don't use same ifname multiple times ([f4e9ea87](https://github.com/dracutdevs/dracut/commit/f4e9ea879f38bea92069e9397028caa5d81e5aee))
* **network-legacy:**
  *  check if dhclient has --timeout option ([23654c50](https://github.com/dracutdevs/dracut/commit/23654c50b003612d1b6e4b09c0bde7dd88239fd8))
  *  correct wrong local network configuration path ([2eb733cc](https://github.com/dracutdevs/dracut/commit/2eb733cc11c09358b79e2c73218953f5bb64da93))
* **network-manager:**
  *  always install the library plugins directory ([429f9de1](https://github.com/dracutdevs/dracut/commit/429f9de1c767c816301097a42cec762dc82d67da))
  *  correct wrong local network configuration path ([744c6de5](https://github.com/dracutdevs/dracut/commit/744c6de5cde38d012f93bc53f9076bf9c37b8b72))
* **nfs,virtiofs:**  check kernel for builtin fs drivers ([78cafe46](https://github.com/dracutdevs/dracut/commit/78cafe465d972ed52cc9d847c9895716a5f44e7e))
* **nvmf:**
  *  run cmdline hook before parse-ip-opts.sh ([a65fab69](https://github.com/dracutdevs/dracut/commit/a65fab69662d3adf52eb968411f59ebc5a173f7c))
  *  avoid calling "exit" in a cmdline hook ([a93968b0](https://github.com/dracutdevs/dracut/commit/a93968b07567a654d18b8ef2144337d803186eca))
  *  make sure "rd.nvmf.discover=fc,auto" takes precedence ([556ef46a](https://github.com/dracutdevs/dracut/commit/556ef46aa96650d72b2fd850a09fa04dff64bbb8))
  *  don't use "finished" queue for autoconnect ([e93e4652](https://github.com/dracutdevs/dracut/commit/e93e46520dd89a7357a15441ab6b141ff9ff9aeb))
  *  don't create did-setup file ([03921ec0](https://github.com/dracutdevs/dracut/commit/03921ec09e95ea49f89ae307dcca4e2e3d1bc6d6))
  *  no need to load the nvme module ([a3cf4ec9](https://github.com/dracutdevs/dracut/commit/a3cf4ec92202df43adf368c7fdd12e35d304a0e4))
  *  don't try to validate network connections in cmdline hook ([b3ff3f3f](https://github.com/dracutdevs/dracut/commit/b3ff3f3fbce6878a754332cd4a05374e5e1156c8))
  *  nvme list-subsys prints the address using commas as separator ([9664e98b](https://github.com/dracutdevs/dracut/commit/9664e98b5db603567d42d4d0c6e6ea1bd3d5bf24))
* **shell-completion:**  add missing -p and --parallel options ([b30a00c2](https://github.com/dracutdevs/dracut/commit/b30a00c2a2815517e79eeaeef5f76fd6f923e61f))
* **skipcpio:**  ignore broken pipe ([aa0369a4](https://github.com/dracutdevs/dracut/commit/aa0369a4a31764fde06214358b0774fb1095af01))
* **squash:**  build ld cache for squash loader ([bc1b23c2](https://github.com/dracutdevs/dracut/commit/bc1b23c29202023dd7852f4c3e3e97aaaf94da92))
* **systemd:**
  *  add missing modprobe@.service ([928252a1](https://github.com/dracutdevs/dracut/commit/928252a145ca44627ba5873e01245eabe246992f))
  *  set right permissions for the machine-id file ([da55e266](https://github.com/dracutdevs/dracut/commit/da55e2663499f6218d28783076c5449a9a6b8ec9))
* **systemd-coredump:**  correct systemd-coredump binary path ([4b931bfb](https://github.com/dracutdevs/dracut/commit/4b931bfb4f594834d06787b3506c4a0ddbbe48ac))
* **systemd-hostnamed:**
  *  add missing dbus-org.freedesktop.hostname1.service ([4fca292b](https://github.com/dracutdevs/dracut/commit/4fca292b957c8ec256111442ba0db4e539442ac8))
  *  correct sysusers configuration ([a540c95b](https://github.com/dracutdevs/dracut/commit/a540c95bbf9496f7b9d6e86aa5080173d73dff78))
* **systemd-networkd:**  typo in systemd-networkd.socket local conf path ([d4732be8](https://github.com/dracutdevs/dracut/commit/d4732be87782016c2699fbf980d63ac366819942))
* **systemd-timedated:**  add missing dbus-org.freedesktop.timedate1.service ([b3d219b4](https://github.com/dracutdevs/dracut/commit/b3d219b475c8f695ccfb8b741282583da710befa))
* **systemd-timesyncd:**  typo in systemd-time-wait-sync.service local conf path ([e3ec51e1](https://github.com/dracutdevs/dracut/commit/e3ec51e128135d56c3995d87ca2a4ff65b253391))
* **test:**  remove unnecessary setup steps ([22ab7979](https://github.com/dracutdevs/dracut/commit/22ab79794852eced9caaccd8763332b870e97032))
* **virtiofs:**
  *  make shebangs work on split-usr systems ([27b316df](https://github.com/dracutdevs/dracut/commit/27b316df1f001949675fbeddaeab6ff56bc449d2))
  *  ismounted has a dependency on the base module ([c73e7b99](https://github.com/dracutdevs/dracut/commit/c73e7b99db8c759d89236d0791145d6919abd2bc))
* **zipl:**  remove trailing spaces from zipl boot device name ([b4de9ee1](https://github.com/dracutdevs/dracut/commit/b4de9ee107742c8b0b8a86dcc22aa4fd366b068e))

#### Features

* **dmsquash-live:**
  *  add support for dash ([862ba526](https://github.com/dracutdevs/dracut/commit/862ba52683834f87722cae7a6692a59d09271ec3))
  *  add new dmsquash-live-autooverlay module ([a3c67d27](https://github.com/dracutdevs/dracut/commit/a3c67d27e75223bb45df19f850d246ced9a09938))
* **dracut-init.sh:**
  *  introduce a new helper require_kernel_modules ([d3a5e631](https://github.com/dracutdevs/dracut/commit/d3a5e6312a84b29bcb10fd5d28e1314f1acbc78f))
  *  add inst_libdir_dir() helper ([cc669250](https://github.com/dracutdevs/dracut/commit/cc669250affa0176ed2bba866d8e933fb0668f4c))
* **dracut-install:**  convert_abs_rel: canonicalise parent of from, too ([53dd6a9b](https://github.com/dracutdevs/dracut/commit/53dd6a9bbb0eb91dea0e56bec556bf865a920b2e), closes [#1781](https://github.com/dracutdevs/dracut/issues/1781))
* **dracut.sh:**
  *  populate uefi_cmdline if no other cmdline is given ([1157143d](https://github.com/dracutdevs/dracut/commit/1157143d67b02ccf95602ae082f6fbfd1a20f342))
  *  pass engine flag to sbsign allowing use with hardware devices ([897e5eff](https://github.com/dracutdevs/dracut/commit/897e5effe08f15de6b20099caeda7bc1167b7026))
* **fs-lib:**  fsck_single can now handle PARTLABEL and PARTUUID ([d40617f7](https://github.com/dracutdevs/dracut/commit/d40617f720ce7d895be4f6297ac4342d4492c39a))
* **github:**  automating dependency updates ([bdddfd56](https://github.com/dracutdevs/dracut/commit/bdddfd561f38469b3f51d7e6af196ff1f190e2a2))
* **kernel-modules:**  exclude USB drivers in strict hostonly mode ([7debf540](https://github.com/dracutdevs/dracut/commit/7debf540ca69d9171cb86b4752c882bac997c26e))
* **multipath:**  install tmpfiles.d config file ([cf31fcf8](https://github.com/dracutdevs/dracut/commit/cf31fcf804be4dc0fa31885f5185a59b6012cdf4))
* **nvmf:**  set rd.neednet=1 if tcp records encountered ([cf8986af](https://github.com/dracutdevs/dracut/commit/cf8986af7d9a3ce73f330de23d5312f924acea34))
* **overlayfs:**
  *  add new overlayfs module to dracut.spec ([b55563f6](https://github.com/dracutdevs/dracut/commit/b55563f635fb8aad5e141c4fa5d3e486dc2b0b60))
  *  add a new module called overlayfs ([40dd5c90](https://github.com/dracutdevs/dracut/commit/40dd5c90e0efcb9ebaa9abb42a38c7316e9706bd))
* **qemu:**  add efi_secret driver ([8194f72a](https://github.com/dracutdevs/dracut/commit/8194f72af2e9b6ab3cdb01412381023b0a58c852))
* **squash:**  use require_kernel_modules for better module checking ([d4a9d6b4](https://github.com/dracutdevs/dracut/commit/d4a9d6b4c006a375e0b89396251e8ad1aecc0b16))
* **systemd:**  install systemd-sysroot-fstab-check ([23684e4a](https://github.com/dracutdevs/dracut/commit/23684e4a2bb024595ad63d9f49d83b4693537110))
* **systemd-pcrphase:**  introducing the systemd-pcrphase module ([d345ca2e](https://github.com/dracutdevs/dracut/commit/d345ca2efd5e017be5cc80cfc96137a7f0bee425))
* **systemd-portabled:**  introducing the systemd-portabled module ([03babd95](https://github.com/dracutdevs/dracut/commit/03babd95e28bc884e87fd0885edafb2ee91f8935))
* **systemd-pstore:**  introducing the systemd-pstore module ([758f2e69](https://github.com/dracutdevs/dracut/commit/758f2e69374d7865bf55a74ee218a1d52df20123))
* **test:**  add new module to share code between tests ([f5689b42](https://github.com/dracutdevs/dracut/commit/f5689b42bdb9dfcb0f1b610d7db845ceac985061))
* **test-makeroot:**  add new module to share code between tests ([54b963ca](https://github.com/dracutdevs/dracut/commit/54b963ca35a3a4cc8bcdb35e5e9ebb74af09191e))
* **test-root:**  add new module to share code between tests ([b17a3103](https://github.com/dracutdevs/dracut/commit/b17a3103a516b5a45af954b1e2969a5256fffebc))

#### Performance

* **90kernel-modules:**  use awk instead of shell monster ([77ac95d9](https://github.com/dracutdevs/dracut/commit/77ac95d9091afcfdbd1fe0372389613914dd1bc6))
* **dracut-install:**
  *  convert_abs_rel: don't allocate target parent realpath ([d2648f6d](https://github.com/dracutdevs/dracut/commit/d2648f6dd8277c3d9a0b8d05ca66a212da47070e))
  *  strdup()+[dirlen]=0 => strndup ([e7d6a1e3](https://github.com/dracutdevs/dracut/commit/e7d6a1e30c34134d27c0ae921b7d18525ddf3dea))
* **dracut.sh:**  do not mkdir $initdir/lib/dracut within a loop ([8d46cc01](https://github.com/dracutdevs/dracut/commit/8d46cc01a95afc6902e8c86a795db082622a3c74))

#### Contributors

- Laszlo Gombos <laszlo.gombos@gmail.com>
- Antonio Alvarez Feijoo <antonio.feijoo@suse.com>
- Martin Wilck <mwilck@suse.de>
- Kairui Song <kasong@tencent.com>
- Marcos Mello <marcosfrm@gmail.com>
- наб <nabijaczleweli@nabijaczleweli.xyz>
- David Tardon <dtardon@redhat.com>
- Jóhann B. Guðmundsson <johannbg@gmail.com>
- Matt Coleman <matt@datto.com>
- Pavel Valena <pvalena@redhat.com>
- Alberto Planas <aplanas@suse.com>
- Brian C. Lane <bcl@redhat.com>
- Jonathan Lebon <jonathan@jlebon.com>
- Lukas Nykryn <lnykryn@redhat.com>
- keentux <valentin.lefebvre@suse.com>
- Cole Robinson <crobinso@redhat.com>
- Daan De Meyer <daan.j.demeyer@gmail.com>
- Frederick Grose <4335897+FGrose@users.noreply.github.com>
- Frederick Grose <fgrose@sugarlabs.org>
- Hari Bathini <hbathini@linux.ibm.com>
- Henrik Gombos <henrik99999@gmail.com>
- Jeremy Linton <jlinton@redhat.com>
- Kenneth D'souza <kennethdsouza94@gmail.com>
- Laura Hild <lsh@jlab.org>
- Mike Gilbert <floppym@gentoo.org>
- Mikhail Novosyolov <m.novosyolov@rosalinux.ru>
- Neal Gompa <neal@gompa.dev>
- Scott Moser <smoser@brickies.net>
- Tao Liu <ltao@redhat.com>
- Tianhao Chai <cth451@gmail.com>
- gombi <gombi@>
- joamonwx <unknown>
- runsisi <runsisi@hust.edu.cn>
- tupper <tupper.bob@gmail.com>

dracut-057
==========

#### Bug Fixes

* **10i18n:**
  *  stop leaking shell options ([f3441cc7](https://github.com/dracutdevs/dracut/commit/f3441cc7c577554dde04a9fe90638f779bb0a411))
  *  stop leaking shell options ([35064768](https://github.com/dracutdevs/dracut/commit/35064768ebf14d3ec6bf3f7df52580fb4920ea3d))
* **Makefile:**  use of potentially unset variable ([1354d633](https://github.com/dracutdevs/dracut/commit/1354d6339a2e603fe0787bc028f9e7e1d49cbf82))
* **bluetooth:**
  *  accept compressed firmwares in inst_multiple ([09a1e5af](https://github.com/dracutdevs/dracut/commit/09a1e5afd2eaa7f8e9f3beaf8a48283357e7fea0))
  *  nullglob should not be needed ([36aaa74f](https://github.com/dracutdevs/dracut/commit/36aaa74f3641d375cb435298864fad1945444893))
  *  make $dbussystem/bluetooth.conf optional ([a38d9ec0](https://github.com/dracutdevs/dracut/commit/a38d9ec0320f3819a3b70dc5bb59f6d2fc570149))
* **configure:**  check for SYS-gettid during configure ([0ef40d88](https://github.com/dracutdevs/dracut/commit/0ef40d88124fe67726b8b5d8321dce064c727447))
* **connman:**  copy netroot.sh from the network module and install it ([f6d83f9f](https://github.com/dracutdevs/dracut/commit/f6d83f9f5cd4850468f26048f8eed015dc2bd0e0))
* **crypt:**  add missing is_keysource parameter to cryptroot-ask ([6c11a8fc](https://github.com/dracutdevs/dracut/commit/6c11a8fcee08c297a34bd5c5215a7a29d3529b85))
* **dmsquash-live:**
  *  mount live device with the correct type ([08ed7b2d](https://github.com/dracutdevs/dracut/commit/08ed7b2d0035eaa699c139bc9719f90190f6ffc1))
  *  permanent overlay on the same drive as LiveCD .iso ([9a884b3a](https://github.com/dracutdevs/dracut/commit/9a884b3afce1ebc8c6a6e5f62594ce708486a826))
* **dracut:**  default to correct firmware search paths ([95aeed89](https://github.com/dracutdevs/dracut/commit/95aeed8975dd5a2af782ec986f2af6176b585c59))
* **dracut-functions.sh:**  correct wrong comment ([0afa840e](https://github.com/dracutdevs/dracut/commit/0afa840e111e63da14edcb655886734b45d61c4b))
* **dracut-initramfs-restore.sh:**
  *  unpack uncompressed initrd as last option ([46886956](https://github.com/dracutdevs/dracut/commit/46886956211f8a436e2e9f81fc4972d2a297c3a3))
  *  check if SELINUXTYPE is set ([24d8f35b](https://github.com/dracutdevs/dracut/commit/24d8f35b9c162f42c58abd27fe9c75bbf76cbfe7))
* **dracut-install:**
  *  copy files preserving ownership attributes ([9ef73b6a](https://github.com/dracutdevs/dracut/commit/9ef73b6ad08c19c3906564e5a15c7908ed9a81c8))
  *  do not fail when SOURCE is optional and missing ([bd1a5ca9](https://github.com/dracutdevs/dracut/commit/bd1a5ca9ae9e347061e67e51be29335ab074ad95))
* **dracut-systemd:**
  *  drop misleading man page reference ([77c28b30](https://github.com/dracutdevs/dracut/commit/77c28b3020b7dede848d8282151f609d80905b05))
  *  correct service dependencies ([85fdff12](https://github.com/dracutdevs/dracut/commit/85fdff1212e708d335f035926f3c2a6b87bb1c3c))
* **dracut.cmdline.7:**  {=> must} also be specified ([27071e9a](https://github.com/dracutdevs/dracut/commit/27071e9a0e7928bccc45469eb659cdafb20f134b))
* **dracut.sh:**
  *  format usage and add missing options ([9bef7109](https://github.com/dracutdevs/dracut/commit/9bef71094eba84a9eac161fc45386ccd73bd2b34))
  *  always check that MACHINE_ID is not empty ([527fdfa1](https://github.com/dracutdevs/dracut/commit/527fdfa1517b7f010afa049fe6add71e4c916cdd))
  *  avoid calling dfatal before dracut-logger is sourced ([012d7db2](https://github.com/dracutdevs/dracut/commit/012d7db27da7416471ed49ee2ca666ab95837f47))
  *  add missing default output file paths ([28ef3bc6](https://github.com/dracutdevs/dracut/commit/28ef3bc6a6f1efcd8d8c16228a6dee9d563342e7))
  *  add missing --libdirs usage ([352e5917](https://github.com/dracutdevs/dracut/commit/352e59173152f13b242c598a735243f0f2850ff1))
  *  drop restorecon call ([33859892](https://github.com/dracutdevs/dracut/commit/3385989266ddb1c0685f9f7501f1835e9ce49730))
  *  error exporting sysctl variables ([4c355d05](https://github.com/dracutdevs/dracut/commit/4c355d05587b0432a6dc551b8693dbdc51a07962))
* **dracut.spec:**  add connman module ([d0c6ab21](https://github.com/dracutdevs/dracut/commit/d0c6ab21d906cc5b0e05e1107c48baffcbedb02c))
* **fedora.conf:**  vi binary is missing ([48541362](https://github.com/dracutdevs/dracut/commit/485413627f04fdc0c5c29958ce437718b262a99c))
* **github:**  remove packit ([8fd37d20](https://github.com/dracutdevs/dracut/commit/8fd37d20f4b7cc08ee0970e0249aac4cd5b47a4e))
* **ifcfg:**  avoid calling unavailable dracut-logger functions ([7103c4bc](https://github.com/dracutdevs/dracut/commit/7103c4bce9240d5896a0d207c216e0f6270ad2e8))
* **install:**  restore musl support ([ce55a85e](https://github.com/dracutdevs/dracut/commit/ce55a85ed5d902c19d75895508856f96ec2ceb1a))
* **integrity:**  do not display any error if there is no IMA certificate ([f63f411d](https://github.com/dracutdevs/dracut/commit/f63f411d52df613936082d646ab072447b8b9d7f))
* **iscsi:**
  *  do not exit in handle_netroot() if discovery failed ([319dc7fe](https://github.com/dracutdevs/dracut/commit/319dc7fe10585a19d1a051f8ad1ba0190f86ff1f))
  *  remove unneeded iscsi NOP-disable code ([a33a8df4](https://github.com/dracutdevs/dracut/commit/a33a8df43d33c9bdf85d7a5b7392585129a690f5))
* **kernel-network-modules:**  allow specifying empty --hostonly-nics ([ab6f5733](https://github.com/dracutdevs/dracut/commit/ab6f57339ad77b5bc116400f7b66580745bfc563))
* **lsinitrd.sh:**
  *  always check that MACHINE_ID is not empty ([d6343146](https://github.com/dracutdevs/dracut/commit/d6343146c1db69fc724ca666a5d9321af7fd0d46))
  *  add missing default paths ([49ea6c42](https://github.com/dracutdevs/dracut/commit/49ea6c42db7180eec5ba57e082a38d116f2d17a5))
* **lvm:**
  *  add missing grep requirement ([79f9d9e1](https://github.com/dracutdevs/dracut/commit/79f9d9e1c29a9c8fc046ab20765e5bde2aaa3428))
  *  ignore expected error message from lvm config ([7e03d81f](https://github.com/dracutdevs/dracut/commit/7e03d81fe3df932558d2b7280fa57da24ba955c0))
* **man:**
  *  add missing default paths ([ffc1985c](https://github.com/dracutdevs/dracut/commit/ffc1985cb26894c50487b7db2703e8715a4a7537))
  *  add missing --libdirs section ([a90dbd95](https://github.com/dracutdevs/dracut/commit/a90dbd958b19778044047f17559449fffdb94cc2))
* **network-manager:**  avoid calling unavailable dracut-logger functions ([b7059aef](https://github.com/dracutdevs/dracut/commit/b7059aef5962aad1dc8d96a0f600105a40867380))
* **nfs:**
  *  give /run/rpcbind ownership to rpc user ([d6159343](https://github.com/dracutdevs/dracut/commit/d615934311e25146bb37943bf1385a19dfdbd9e8))
  *  require and install needed binaries ([0e4df7a3](https://github.com/dracutdevs/dracut/commit/0e4df7a39dda388dc71ff6f749c8197cba4442b9))
* **nvmf:**
  *  deprecate old nvmf cmdline options ([e405501e](https://github.com/dracutdevs/dracut/commit/e405501e23462d151bba252133f4a6179bf79cf0))
  *  set executable bit on nvmf-autoconnect.sh ([25a92885](https://github.com/dracutdevs/dracut/commit/25a92885a9519701cc480298c2b082e2e2bf5ebe))
* **plymouth:**  hide dpkg-architecture stderr messages ([42e9d188](https://github.com/dracutdevs/dracut/commit/42e9d1889298c3d8badfb6f95e16e048ad83a1f6))
* **resume:**  correct call to block_is_netdevice function ([a7a4b76c](https://github.com/dracutdevs/dracut/commit/a7a4b76c4ad5794f5f8a24ecd5b495f1512d05f7))
* **shell-completion:**  add missing options ([1199f990](https://github.com/dracutdevs/dracut/commit/1199f990bb93b4e6bd56fa3df050b17fc7e6c378))
* **systemd-coredump:**  add systemd-sysusers dependency ([ce82e969](https://github.com/dracutdevs/dracut/commit/ce82e969f8faaccbb57be178833ef4e39f01cdf9))
* **systemd-journald:**  remove duplicate entry in inst_multiple ([d3ab2061](https://github.com/dracutdevs/dracut/commit/d3ab20615ef94370e43b042d913d5f787dd52430))
* **systemd-timesyncd:**  add systemd-sysusers dependency ([28b6adcb](https://github.com/dracutdevs/dracut/commit/28b6adcb27fb5240c01f7d41511ce02597aa27bd))
* **test:**
  *  dmsquash-live test without an iso ([6ee2baf3](https://github.com/dracutdevs/dracut/commit/6ee2baf314fc6aa3bb88ca52d11c9f599223eb77))
  *  remove stale comments ([b3ab3037](https://github.com/dracutdevs/dracut/commit/b3ab3037e8b9272498ed40131f30bf1831acab73))
  *  add support for dpkg to pass the test on debian ([a7dfdf6a](https://github.com/dracutdevs/dracut/commit/a7dfdf6acbf7a87fd2735541f06a062126966f69))
  *  nullglob should not be needed ([c7b3ac2b](https://github.com/dracutdevs/dracut/commit/c7b3ac2bd115521855b3ad8ce287cb1a9afca128))
* **udev-rules:**  add cdrom udev rules by default ([aebeb2ec](https://github.com/dracutdevs/dracut/commit/aebeb2ecdf76b7716fadbab8b216b8805d36a461))

#### Features

 *   add aarch64 uefi support ([8391a993](https://github.com/dracutdevs/dracut/commit/8391a993033e212a24635dd629c167354f0834f8))
 * **connman:**  introduce connman support module ([f30d0351](https://github.com/dracutdevs/dracut/commit/f30d03513f357a36d2ed48a522c7ef2a46bb0c5c))
 * **dracut:**
   *  support parallel execution with --parallel ([6d923262](https://github.com/dracutdevs/dracut/commit/6d92326201014cde9ab04b90367017f875d3b991))
   *  add zfs detection ([9582f027](https://github.com/dracutdevs/dracut/commit/9582f02773c5115e14fe0992ec2db3935cb0e6eb))
 * **dracut-install:**  support ZSTD-compressed firmware with .zst suffix ([9d8387ed](https://github.com/dracutdevs/dracut/commit/                             9d8387ed803dfc3e8b97d2e415a15083774d7ac6))
 * **dracut-systemd:**  use Documentation= to point to man page ([42e8f17c](https://github.com/dracutdevs/dracut/commit/                                       42e8f17c2481d33a3d6ba23f653c835e0cda6994))
 * **gensplash:**  remove module ([1befc641](https://github.com/dracutdevs/dracut/commit/1befc6416743a527824f0f2cc25471e86a6f8a79))
 * **lvm:**  add new module lvmthinpool-monitor ([d9812fc4](https://github.com/dracutdevs/dracut/commit/d9812fc4ae18a39c144140dd60cb03e16e0d2e06))
 * **man:**  add documentation for rd.luks.key.tout ([65e41b54](https://github.com/dracutdevs/dracut/commit/65e41b54600878e3e08bbe3b60f66524e1d166a8))
 * **squash:**
   *  add shell completion for --squash-compressor option ([e2aee2d4](https://github.com/dracutdevs/dracut/commit/e2aee2d436cf68c4515a381d620a963ff18dcf05))
   *  update the manual page for --squash-compressor ([3693bfef](https://github.com/dracutdevs/dracut/commit/3693bfef2fc252f5a4b18278c87a1076896b7fb5))
   *  decouple the compressor for dracut and dracut-squash ([90d9ae8c](https://github.com/dracutdevs/dracut/commit/90d9ae8ca814c26045ecea63fa15bd8959076d0d))
 * **url-lib.sh:**  add --retry-connrefused to default curl arguments ([90032a46](https://github.com/dracutdevs/dracut/commit/                                 90032a463190ab68f20f493894f667320466082d))
 * **virtiofs:**  virtiofs root filesystem support ([4632f799](https://github.com/dracutdevs/dracut/commit/4632f799954c18eb8f655efe05b1e6ce30246828))

#### Contributors

- Antonio Alvarez Feijoo <antonio.feijoo@suse.com>
- Laszlo Gombos <laszlo.gombos@gmail.com>
- Pavel Valena <pvalena@redhat.com>
- David Tardon <dtardon@redhat.com>
- Tao Liu <ltao@redhat.com>
- наб <nabijaczleweli@nabijaczleweli.xyz>
- German Maglione <gmaglione@redhat.com>
- Jóhann B. Guðmundsson <johannbg@gmail.com>
- Nicolas Porcel <nicolasporcel06@gmail.com>
- Zoltán Böszörményi <zboszor@gmail.com>
- nkraetzschmar <nkraetzschmar@users.noreply.github.com>
- Benjamin Gilbert <bgilbert@redhat.com>
- Coiby Xu <coxu@redhat.com>
- Conrad Hoffmann <ch@bitfehler.net>
- David Teigland <teigland@redhat.com>
- James Morris <morisja@gmail.com>
- Lee Duncan <lduncan@suse.com>
- Martin Wilck <mwilck@suse.de>
- Masahiro Matsuya <mmatsuya@redhat.com>
- Michal Hecko <mhecko@redhat.com>
- Morten Linderud <morten@linderud.pw>
- Savyasachee Jha <genghizkhan91@hawkradius.com>
- Shreenidhi Shedi <sshedi@vmware.com>
- Wenchao Hao <haowenchao@huawei.com>

dracut-056
==========

#### Bug Fixes

* **base:**
    *  do not change the provided UUID ([4e858741](https://github.com/dracutdevs/dracut/commit/4e858741087a5cfea891bd2c1fd51ea9b830aeaf))
    *  add default device choice ([e8c18c9f](https://github.com/dracutdevs/dracut/commit/e8c18c9f7f5ed94898f70e9ff5a5f94a815a2b49))
    *  tr needs to be installed ([dfbfd33b](https://github.com/dracutdevs/dracut/commit/dfbfd33b24524c0c10ad3594be143192f5b7da84))
    *  do not quote $initargs for switch_root ([f649cd10](https://github.com/dracutdevs/dracut/commit/f649cd10b2e920e9d65c532db9b9f89a7370ad99))
    *  repair installing dracut-util ([d7acf107](https://github.com/dracutdevs/dracut/commit/d7acf107f2ac619f73dfa29588ea9adfaf79e296))
* **bluetooth:**
    *  make hostonly configuration files optional ([d03fb675](https://github.com/dracutdevs/dracut/commit/d03fb675d8e904c6c44de9b91814b33c45043f4f))
    *  dbus configuration path fixes ([34b1dd2e](https://github.com/dracutdevs/dracut/commit/34b1dd2e26c343e9000094db01a7985b6851adf1))
* **cms:**  reload NetworkManager connections ([07977ee5](https://github.com/dracutdevs/dracut/commit/07977ee5c5294a5d30c1f33f292a0b31303750fb))
* **cpio:**
    *  correct dev_t -> rmajor/rminor mapping ([acc629ab](https://github.com/dracutdevs/dracut/commit/acc629abb0d7a26f692f99e5a9cf8c8401bc6a86))
    *  write zeros instead of seek for padding and alignment ([0af11c5e](https://github.com/dracutdevs/dracut/commit/0af11c5ea5018a3e1049a2207a9a671049651876))
* **crypt:**  remove quotes from cryptsetupopts ([e0abf88a](https://github.com/dracutdevs/dracut/commit/e0abf88a15d23fbf793cf872397016ad86aeaaa8), closes [#1528](https://github.com/dracutdevs/dracut/issues/1528))
* **crypt-gpg:**
    *  tr needs to be installed ([a93fbc4a](https://github.com/dracutdevs/dracut/commit/a93fbc4ae00d8c6ecda67319a6425f7966609bbe))
    *  execute --card-status on each try ([66100936](https://github.com/dracutdevs/dracut/commit/6610093698db25fda1d584b9771da1e2c2330095))
* **dasd_rules:**
    *  correct udev dasd rules parsing ([5de6e4d5](https://github.com/dracutdevs/dracut/commit/5de6e4d56e5206cb47f645ad1cb6d39794048c68))
    *  remove collect based udev rule creators ([ebafbd82](https://github.com/dracutdevs/dracut/commit/ebafbd824175e201ae9476576588a896c6b7d7eb))
* **dmsquash-live:**
    *  option to use overlayfs on a block device root ([813577e2](https://github.com/dracutdevs/dracut/commit/813577e2ba034b448d2cf2d2857b2d20d56c0259))
    *  do not install systemd files when systemd is not enabled ([bf8738d3](https://github.com/dracutdevs/dracut/commit/bf8738d31ca53ad6410c46c1f9b2a4a12273b9a3))
    *  iso-scan requires rmdir ([e19e3890](https://github.com/dracutdevs/dracut/commit/e19e38904c054664473207d2d6ef3c53bd938867))
    *  correct regression introduced with shellcheck changes ([0c631efb](https://github.com/dracutdevs/dracut/commit/0c631efb10bf4ce18ec8640277bd94712950298a))
* **dmsquash-live-ntfs:**  fuse3 no longer requires ulockmgr_server ([75ad2699](https://github.com/dracutdevs/dracut/commit/75ad269931eccd266a5d60ba4000d93655143e00))
* **dracut:**  be more robust when using 'set -u' ([22a80629](https://github.com/dracutdevs/dracut/commit/22a80629b4bbcef02eb8fe3611ea44e253ef4c61))
* **dracut-functions.sh:**
    *  ip route parsing ([d754e1c6](https://github.com/dracutdevs/dracut/commit/d754e1c6f081a6501cb7fdcb5caaa6c4977235af))
    *  get block device driver if in a virtual subsystem ([dc3b976f](https://github.com/dracutdevs/dracut/commit/dc3b976f3393d7a3fb75b349418fc8ee2c9142bd))
* **dracut-init:**  unbreak a comment ([bc4f196f](https://github.com/dracutdevs/dracut/commit/bc4f196f9825029eaef7ccf525ec57f5229b2793))
* **dracut-initramfs-restore.sh:**
    *  add missing compression options ([e86397de](https://github.com/dracutdevs/dracut/commit/e86397de24f4efa6d36e2bb5ae84b7d9ec69b72d))
    *  add missing default paths ([3d8e1ad2](https://github.com/dracutdevs/dracut/commit/3d8e1ad2ae1e34244ddf700beea6358c1452e05c), closes [#1628](https://github.com/dracutdevs/dracut/issues/1628))
* **dracut-install:**  tweaks to get_real_file() ([1beeaf3b](https://github.com/dracutdevs/dracut/commit/1beeaf3b71aed763d5fc7a9ee044d675f8906e8c))
* **dracut-shutdown:**  add cleanup handler on failure ([7ab1d002](https://github.com/dracutdevs/dracut/commit/7ab1d00227cad6f1b86ba01fdc766769faebb031))
* **dracut-systemd:**  do not use Requires for vconsole-setup.service ([a7f5429c](https://github.com/dracutdevs/dracut/commit/a7f5429cb81f7ffdf9bd5684af8d36725170b756))
* **dracut.sh:**
    *  do not ignore invalid config file or dir path ([7de9ffc0](https://github.com/dracutdevs/dracut/commit/7de9ffc0574790ecbad74b5a000ecd022d7736d4))
    *  check kernel zstd support early ([475497b1](https://github.com/dracutdevs/dracut/commit/475497b1bd12c006c782541124b6427cb7ef4cb7))
    *  check availability of configured compression ([bdac657b](https://github.com/dracutdevs/dracut/commit/bdac657bf65615438942a872491a818750735014))
    *  inform user about auto-selected compression method ([06d47ded](https://github.com/dracutdevs/dracut/commit/06d47ded679231e1370cc655c1df408fc865baac))
    *  drop pointless check for module compression method ([586d3e76](https://github.com/dracutdevs/dracut/commit/586d3e7664c00bf144becfa69dde2dbab8711d51))
    *  change misspelled variable name ([acfd97a9](https://github.com/dracutdevs/dracut/commit/acfd97a94385c33cd6cef4e5a37f233ea4081288))
    *  remove wrong $ in loop sequence ([f1245b5b](https://github.com/dracutdevs/dracut/commit/f1245b5bc13a98ef0dcc679dcef6148214e09503))
    *  handle symlinks appropriately while using '-i' option ([c7fbc0c8](https://github.com/dracutdevs/dracut/commit/c7fbc0c8901917baf0d1f0822568e65c6ec00d18))
    *  handle '-i' option to include files beginning with '.' ([f1138012](https://github.com/dracutdevs/dracut/commit/f1138012c9dc44e6614466c0a8e929fc55e4a5dd))
* **drm:**  add privacy screen modules to the initrd ([14d97a6a](https://github.com/dracutdevs/dracut/commit/14d97a6a28c6172340c47c89374358aaf4e2629d))
* **fedora.conf.example:**  rename misspelled variable ([9371dcab](https://github.com/dracutdevs/dracut/commit/9371dcaba3c58377428eee44bd702fae7b2ab20e))
* **fido2:**  add a missing library ([4753738b](https://github.com/dracutdevs/dracut/commit/4753738b62d958955f50fb077ea21c56a8d23dc3))
* **fips:**
    *  missing sourcing of dracut-lib ([857b17f0](https://github.com/dracutdevs/dracut/commit/857b17f090bdf575292f0bd6f5e8e3d753f6b426))
    *  add and remove local variables ([e8121bfd](https://github.com/dracutdevs/dracut/commit/e8121bfddda34e20db889a74d4ac6259ed182aea))
    *  wrong error message ([7f10c483](https://github.com/dracutdevs/dracut/commit/7f10c483b6abcc8be42cf246bbdade264be68228))
    *  handle s390x OSTree systems ([78557f05](https://github.com/dracutdevs/dracut/commit/78557f05a69fe718a97df85d2ed741ce10d3f806))
* **fips.sh:**  repsect rd.fips.skipkernel ([5789abcb](https://github.com/dracutdevs/dracut/commit/5789abcbe05f30d556086590b786c4857d025d9d))
* **img-lib:**  install rmdir ([51ce8893](https://github.com/dracutdevs/dracut/commit/51ce8893d981e90640123a7dcc3e4f3621e7d819))
* **install:**
    *  segfault on popen error ([5c2f72f1](https://github.com/dracutdevs/dracut/commit/5c2f72f152ec319a8001d1ff0bfd1f81a9130b04))
    *  extend hwcaps library handling to libraries under glibc-hwcaps/ ([10ed204f](https://github.com/dracutdevs/dracut/commit/10ed204f873f454dcd15ffcc82dc3a1c781c1514))
    *  use size_t to avoid -Wsign-compare warning ([55468a2d](https://github.com/dracutdevs/dracut/commit/55468a2d40182de4cce5ba4ecd5dcd96be03bd4d))
    *  improve gettid definition ([ef0f848a](https://github.com/dracutdevs/dracut/commit/ef0f848a67fdd0a0dab135acbd1cd7fa0179a95c))
    *  validate return values log.c ([19537f89](https://github.com/dracutdevs/dracut/commit/19537f8943ac4106c6d4ab0e00a48a8c0a9a0519))
    *  rectify unused function args in log.c ([b5cf7ec7](https://github.com/dracutdevs/dracut/commit/b5cf7ec784335ec561e379f8e78f48019a344ac0))
    *  use wrapper for asprintf ([e2a61595](https://github.com/dracutdevs/dracut/commit/e2a61595d2c91202ff4ea69937064cd2c0d1f336))
    *  use unsigned int instead of unsigned ([74a41799](https://github.com/dracutdevs/dracut/commit/74a417994840f7a6119e2dee57f9a3bb4d84998b))
    *  reduce cppcheck warnings ([b0bf8187](https://github.com/dracutdevs/dracut/commit/b0bf8187d5cc51d5576d8d70a81677d7c9741b37))
    *  add a missing ret value assignment ([6a444261](https://github.com/dracutdevs/dracut/commit/6a44426162d5b1b7084b17f921799863d353f847))
* **integrity:**  add support for loading multiple EVM x509 certs ([9da76af8](https://github.com/dracutdevs/dracut/commit/9da76af8e7f0f7a939b2ee44f0b4a5ce0bdd3b0b))
* **iscsi:**  add support for the new iscsiadm "no-wait" (-W) command ([7374943a](https://github.com/dracutdevs/dracut/commit/7374943ae3d063f0142c969b132c4156030fda8b))
* **kernel-modules:**
    *  add mailbox drivers for arm ([0e80ff72](https://github.com/dracutdevs/dracut/commit/0e80ff72e01d28e7e92d3adbf98ec40bdbdc37fe))
    *  detect block device's hardware driver ([c86f4d28](https://github.com/dracutdevs/dracut/commit/c86f4d286000d1e76fd405560b4114537e2cbbff))
    *  add blk_mq_alloc_disk and blk_cleanup_disk to blockfuncs ([b292ce72](https://github.com/dracutdevs/dracut/commit/b292ce7295f18192124e64e5ec31161d09492160))
    *  add more modules on RISC-V ([3cc9f1c1](https://github.com/dracutdevs/dracut/commit/3cc9f1c10c67dcdb5254e0eb69f19e9ab22abf20))
    *  add isp1760 USB controller ([15398458](https://github.com/dracutdevs/dracut/commit/15398458685d376fef56b1bf6fe09ae7c68324c1))
    *  add Type-C USB drivers for generic initrd ([a1287c62](https://github.com/dracutdevs/dracut/commit/a1287c627f28b16b1b066b7c256549b832bd98de))
* **kernel-modules-extra:**  handle zstd module extension ([b3d2dcb7](https://github.com/dracutdevs/dracut/commit/b3d2dcb71e7af8f605f5f66041ed3c801333e5f1))
* **lvm:**
    *  restore setting LVM_MD_PV_ACTIVATED ([164e5ebb](https://github.com/dracutdevs/dracut/commit/164e5ebb1199ea3e3d641ce402d8257f0055a529))
    *  replace --partial option ([97543cca](https://github.com/dracutdevs/dracut/commit/97543cca48dfde849396f11c83f9c320e1b91c46))
* **man:**  default value of rd.retry was increased to 180 seconds ([4855242c](https://github.com/dracutdevs/dracut/commit/4855242ce5cb586afd2eebd91df57ce1d28ae6b5))
* **mdraid:**  allow UUID comparison for more than one UUID ([d364ce83](https://github.com/dracutdevs/dracut/commit/d364ce8334fef96f48492bd0fb3b7deac37bbb66))
* **memstrack:**  drop bash runtime requirement ([35822f39](https://github.com/dracutdevs/dracut/commit/35822f39970b369301e0ff54436d5714dd996896))
* **mksh:**  requires printf ([f806a628](https://github.com/dracutdevs/dracut/commit/f806a628aa9aec548e425e81b6ea4ab6f5db26f6))
* **multipath:**
    *  check if mpathconf is available ([4318533e](https://github.com/dracutdevs/dracut/commit/4318533e1493bfab622b64efc1b799426c812c26))
    *  drop ExecStop= setting from service unit ([9491e599](https://github.com/dracutdevs/dracut/commit/9491e599282d0d6bb12063eddbd192c0d2ce8acf))
    *  get config. dir from configuration ([2e3c5444](https://github.com/dracutdevs/dracut/commit/2e3c5444d271cb8f05955858b8fdc367c4ea5c48))
* **multipathd.service:**
    *  drop dependencies on iscsi and iscsid ([6246da40](https://github.com/dracutdevs/dracut/commit/6246da400fa7f527a1ff1c620bf85ac9f6644508))
    *  adapt to upstream multipath-tools unit file ([a247d2bc](https://github.com/dracutdevs/dracut/commit/a247d2bc0d4c6d37a2ea4f3da98dd7902bb37385))
    *  remove dependency on systemd-udev-settle ([371b338a](https://github.com/dracutdevs/dracut/commit/371b338a5f19d40ff4c3216dc0f27f9a00cf4e22))
* **network:**
    *  consistent use of "$gw" for gateway ([3f2c76bb](https://github.com/dracutdevs/dracut/commit/3f2c76bb1456941a28d3333569d2bf18f8624617))
    *  wrong test of wicked unit ([22e68307](https://github.com/dracutdevs/dracut/commit/22e683077a686b592da55e1d247b31f65c95d481))
    *  add errors and warnings when network interface does not exist ([79389352](https://github.com/dracutdevs/dracut/commit/7938935267dd8824f074adf84c219340ad4c8db6))
* **network-manager:**
    *  skip non-directories in /sys/class/net ([d9c3c774](https://github.com/dracutdevs/dracut/commit/d9c3c77437d91d7d66369a3ef701ffc5e501346d))
    *  disable tty output if the console is not usable ([f6e6be24](https://github.com/dracutdevs/dracut/commit/f6e6be245d0cda14d90a0442b688c8dca1410a2e))
    *  show output on console only with rd.debug enabled ([e07b7ad0](https://github.com/dracutdevs/dracut/commit/e07b7ad0e7f5dbb8024336f3075610b3b74ffb2e))
    *  write DHCP filename option to dhcpopts file ([38320fce](https://github.com/dracutdevs/dracut/commit/38320fce56a8d83b79d6c970c491a454ba9de213))
    *  check for nm-initrd-generator in both /usr/{libexec,lib} ([5ee7e249](https://github.com/dracutdevs/dracut/commit/5ee7e249b8cc74461122ccd7efe954b3402c23da))
    *  ensure safe content of /tmp/dhclient."$ifname".dhcpopts ([e509c638](https://github.com/dracutdevs/dracut/commit/e509c638e68a8e3cae446d1a4f9f86e3aa6e7a99))
    *  include nm-daemon-helper binary ([0e590531](https://github.com/dracutdevs/dracut/commit/0e5905315e92dfc095f543fd73db6190db533217))
    *  don't pull in systemd-udev-settle ([a0f12fb6](https://github.com/dracutdevs/dracut/commit/a0f12fb6a09b09f35ab28753d7c4461c10a8b562))
    *  support teaming under NM+systemd ([a97d2ced](https://github.com/dracutdevs/dracut/commit/a97d2cedcf65a9a2fbff2591171f0163c7d3cb46))
    *  pull in network.target in nm-initrd.service ([a97d6e2b](https://github.com/dracutdevs/dracut/commit/a97d6e2b13146783831b166ec5e8b33b29c514b0))
* **network-wicked:**  multiple path corrections ([d3b5bc17](https://github.com/dracutdevs/dracut/commit/d3b5bc17ebadfe8922d1144b3dfd5435d0ecc71a))
* **nvmf:**  validate_ip_conn ([655c65e6](https://github.com/dracutdevs/dracut/commit/655c65e6ced00e7a80c41e96c5f6fe108da07839))
* **qeth_rules:**  check the existence of /sys/devices/qeth/*/online beforehand ([6c71ba41](https://github.com/dracutdevs/dracut/commit/6c71ba4121ae64ccd13fefba68ca327ac623810f))
* **resume:**
    *  resume using /usr/lib64/suspend ([c4593734](https://github.com/dracutdevs/dracut/commit/c459373448d24760d15e22fde7c6f811c7891376))
    *  check for presence of /sys/power/resume ([0b977906](https://github.com/dracutdevs/dracut/commit/0b97790626bff3579755b38f78a9c524a075cfcc))
* **rootfs-block:**  make the base module dependency explicit ([3326e4c9](https://github.com/dracutdevs/dracut/commit/3326e4c957d0499495d9e91182fc574b960ace86))
* **s390_rules:**  drop collect installation ([f905c3a7](https://github.com/dracutdevs/dracut/commit/f905c3a72c975cf6006f266755cc91229132c739))
* **shutdown:**  be robust against forced shutdown ([b9ba3c8b](https://github.com/dracutdevs/dracut/commit/b9ba3c8bb8f0f1328cd1ffaa8dbf64585b28c474))
* **skipcpio:**
    *  calculate and use CPIO_MAGIC_LEN ([3fb8723c](https://github.com/dracutdevs/dracut/commit/3fb8723ce0066b4ba92f6dbfc4373a66d1f551c4))
    *  improve error checking ([f6d16b6b](https://github.com/dracutdevs/dracut/commit/f6d16b6bbd5b8b7ac238c3d2148bebf4e91140a2))
* **squash:**
    *  apply FIPS and libpthread workaround ([5ab18dee](https://github.com/dracutdevs/dracut/commit/5ab18dee996f0eeb2b0bfe354570e1b1af46d025))
    *  remove tailing '/' when installing ld.so.conf.d ([cbd85597](https://github.com/dracutdevs/dracut/commit/cbd85597e3ed6abf64ac17f431da5477eb5aefa0))
    *  keep ld cache under initdir ([dc21638c](https://github.com/dracutdevs/dracut/commit/dc21638c3f0acbb54417f3bfb6294ad5514bf2db))
    *  create relative symlinks ([a2b6be44](https://github.com/dracutdevs/dracut/commit/a2b6be44792b68218e3378a7d844b0f8527a4805))
* **systemd-sysusers:**
    *  use split systemd sysuser configs ([fec93bb2](https://github.com/dracutdevs/dracut/commit/fec93bb22181f80056b40231fca36c422248ade0))
    *  override systemd-sysusers.service ([dcbe23c1](https://github.com/dracutdevs/dracut/commit/dcbe23c14d13ca335ad327b7bb985071ca442f12))
* **tpm2-tss:**
    *  add a missing library ([c656b612](https://github.com/dracutdevs/dracut/commit/c656b612b101e4834e01f9841162e2629a7272f7))
    *  typo in depends() ([8b17105b](https://github.com/dracutdevs/dracut/commit/8b17105bed69ed90582a13d97d95ee19e6581365))
* **url-lib:**
    * SC2086: Double quote to prevent globbing and word splitting ([acb18869](https://github.com/dracutdevs/dracut/commit/acb18869e98687a3f8c172d7e7befaa5326cf67a))
    * SC2046: Quote this to prevent word splitting ([ec50cec3](https://github.com/dracutdevs/dracut/commit/ec50cec3bd9169410df409e077d0487c63c2a627))
    * improve ca-bundle detection ([e3bb1815](https://github.com/dracutdevs/dracut/commit/e3bb1815bbbff1a7e21b857d2ae32bc0410754d5))
    * make pre-pivot hook separetely per nfs mount ([2f091b17](https://github.com/dracutdevs/dracut/commit/2f091b17075f81ff490b05d3d566d736fc32f0be))
* **usrmount:**  do not empty _dev variable ([4afdcba2](https://github.com/dracutdevs/dracut/commit/4afdcba212793f136aea012b30dd7bdb5b641a5a))
* **zfcp_rules:**
    *  correct udev zfcp rules parsing ([59252668](https://github.com/dracutdevs/dracut/commit/5925266832042f9d17a3fb7a219b83118c5b16d6))
    *  remove collect based udev rule creators ([d40c49a8](https://github.com/dracutdevs/dracut/commit/d40c49a8dfe203be33af8ace5f0efd07a88856f4))

#### Features

* **Makefile:**  cargo wrapper for dracut-cpio build ([51d21c6b](https://github.com/dracutdevs/dracut/commit/51d21c6b37b0eb8566d18d665d0197ca4d68101c))
* **cpio:**
    *  add newc archive creation utility ([a9c67046](https://github.com/dracutdevs/dracut/commit/a9c67046431ccf5fd4f4c16c890695df388f0d38))
    *  add rust argument parsing library from crosvm ([94fc5026](https://github.com/dracutdevs/dracut/commit/94fc50262f5e6c28d92782dc231fbb6c61855954))
* **crypt:**
    *  check if pkcs11 module is needed in hostonly mode ([56f4fb6c](https://github.com/dracutdevs/dracut/commit/56f4fb6cb755327c77c32f8c414a4a0e64fc933c))
    *  check if fido2 module is needed in hostonly mode ([d5fd030c](https://github.com/dracutdevs/dracut/commit/d5fd030cc285730e1a1b9e0e78a1e1dc4daabfe0))
    *  check if tpm2-tss module is needed in hostonly mode ([5d990a00](https://github.com/dracutdevs/dracut/commit/5d990a004b5ae6863f2c9a633b184c07dd73563d))
* **dracut.sh:**
    *  add --aggresive-strip option ([67fc670a](https://github.com/dracutdevs/dracut/commit/67fc670a88ab6c97d22c6718082619c0cf850fc3))
    *  add "--enhanced-cpio" option for calling dracut-cpio ([afe4a6db](https://github.com/dracutdevs/dracut/commit/afe4a6dbb7df62982baab8212bba5d90010dfbac))
    *  check if target kernel has zstd support compiled in ([591118c5](https://github.com/dracutdevs/dracut/commit/591118c56da2bfcea060e3b7671bc87b23c0e44a))
* **fido2:**  introducing the fido2 module ([049973b7](https://github.com/dracutdevs/dracut/commit/049973b708298ea0ce1ac9c869b404f4c718eff3))
* **lvm:**
    *  only run lvchange for LV that is seen on devices ([1af46743](https://github.com/dracutdevs/dracut/commit/1af46743195422aaebcde5c508a5dd479eff51ea))
    *  use generated filter when none is set ([7ffc5e38](https://github.com/dracutdevs/dracut/commit/7ffc5e388bcce20785803825bdd260c3c854b34f))
    *  update lvm command options ([c0a54f29](https://github.com/dracutdevs/dracut/commit/c0a54f2993b1d3c2101202c274a41f925445d54b))
* **pcsc:**  introducing the pcsc module ([dcaff88a](https://github.com/dracutdevs/dracut/commit/dcaff88ac942042e3db0a2bbfc1c995ec0735f38))
* **pkcs11:**
    *  include the module in the spec file ([c5907f82](https://github.com/dracutdevs/dracut/commit/c5907f82d835d72e4dd7c473a86e872fce37d61e))
    *  introducing the pkcs11 module ([83ea8cf0](https://github.com/dracutdevs/dracut/commit/83ea8cf001a49356cf7814b3c08bdd1c4b4f2763))
* **spec:**  add systemd-integritysetup module ([fe8df024](https://github.com/dracutdevs/dracut/commit/fe8df0240a24b9d2d60a5b0b998f82b251ede849))
* **squash:**  install umount util ([563f5434](https://github.com/dracutdevs/dracut/commit/563f543424c66bf38e6cbd3f489655d45ad9b5c5))
* **systemd:**  enable support for systemd compiled with ASAN ([d502d2a8](https://github.com/dracutdevs/dracut/commit/d502d2a816ba8f8329b3d8616bd2a7e82a0ad21f))
* **systemd-integritysetup:**  introducing the systemd-integritysetup module ([33cf47a6](https://github.com/dracutdevs/dracut/commit/33cf47a60870cc290bd5b59c9cf87c54ad37051f))

#### Contributors

- Antonio Alvarez Feijoo <antonio.feijoo@suse.com>
- David Disseldorp <ddiss@suse.de>
- Martin Wilck <mwilck@suse.de>
- Jóhann B. Guðmundsson <johannbg@gmail.com>
- Shreenidhi Shedi <sshedi@vmware.com>
- David Teigland <teigland@redhat.com>
- Beniamino Galvani <bgalvani@redhat.com>
- Thomas Blume <thomas.blume@suse.com>
- Kairui Song <kasong@redhat.com>
- Laszlo Gombos <laszlo.gombos@gmail.com>
- Renaud Métrich <rmetrich@redhat.com>
- Dusty Mabe <dusty@dustymabe.com>
- Masahiro Matsuya <mmatsuya@redhat.com>
- Alexander Wenzel <alexander.wenzel@qbeyond.de>
- Andre Russ <andre.russ@sap.com>
- Cornelius Hoffmann <coding@hoffmn.de>
- David Tardon <dtardon@redhat.com>
- Frantisek Sumsal <frantisek@sumsal.cz>
- Harald Hoyer <harald@profian.com>
- José María Fernández <josemariafg@gmail.com>
- Kairui Song <kasong@tencent.com>
- Peter Robinson <pbrobinson@fedoraproject.org>
- Pingfan Liu <piliu@redhat.com>
- Tony Asleson <tasleson@redhat.com>
- Zoltán Böszörményi <zboszor@gmail.com>
- Adrien Thierry <athierry@redhat.com>
- Alexander Tsoy <alexander@tsoy.me>
- Andreas Schwab <schwab@suse.de>
- Andrey Sokolov <keremet@altlinux.org>
- Brandon Sloane <btsloane@verizon.net>
- Charles Rose <charles.rose@dell.com>
- Coiby Xu <coxu@redhat.com>
- Dan Horák <dhorak@redhat.com>
- Dirk Müller <dirk@dmllr.de>
- Glenn Morris <rgm@stanford.edu>
- Hans de Goede <hdegoede@redhat.com>
- Hari Bathini <hbathini@linux.ibm.com>
- Henrik Gombos <henrik99999@gmail.com>
- Jonathan Lebon <jonathan@jlebon.com>
- LinkTed <link.ted@mailbox.org>
- Lubomir Rintel <lkundrak@v3.sk>
- Luca BRUNO <luca.bruno@coreos.com>
- Lukas Nykryn <lnykryn@redhat.com>
- Matthias Berndt <matthias_berndt@gmx.de>
- Mike Gilbert <floppym@gentoo.org>
- Pavel Valena <pvalena@redhat.com>
- Stefan Berger <stefanb@linux.ibm.com>
- Thomas Haller <thaller@redhat.com>
- Tomasz Paweł Gajc <tpgxyz@gmail.com>
- Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl>
- joshuacov1 <joshuacov@gmail.com>
- lapseofreason <lapseofreason0@gmail.com>

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

