pkgname=dracut-git
pkgver=$(date +%s)
pkgrel=$(git log --pretty=format:%h |head -n 1)
pkgdesc="Initramfs generation utility"
arch=('i686' 'x86_64')
url="https://dracut.wiki.kernel.org/"
license=('GPL')
conflicts=('dracut' 'mkinitcpio')
provides=('dracut=9999' 'mkinitcpio=9999')
depends=('bash')
optdepends=('cryptsetup' 'lvm2')
makedepends=('libxslt')
backup=(etc/dracut.conf)
source=()
md5sums=()

build() {
  cd ..
  make sysconfdir=/etc || return 1
  make DESTDIR="${pkgdir}" sysconfdir=/etc install || return 1
}
