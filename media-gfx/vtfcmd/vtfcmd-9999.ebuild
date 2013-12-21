


EAPI=5

inherit toolchain-funcs git-2

DESCRIPTION="Command line VTF (Valve Texture Format) utility"
HOMEPAGE="http://nemesis.thewavelength.net/index.php?p=40
    https://github.com/impiaaa/vtflib-posix"
LICENSE="LGPL-2.1"

SLOT="0"

EGIT_REPO_URI="https://github.com/impiaaa/vtflib-posix.git"
EGIT_BRANCH=master

RDEPEND="media-libs/devil"

src_compile() {
    pwd
    ls -la
    mkdir "${WORKDIR}/${P}/bin"
    emake CC="$(tc-getCC)" CCC="$(tc-getCXX)"
}

src_install() {
    mkdir -p "${D}/usr/bin/"
    cp "${WORKDIR}/${P}/bin/vtfcmd" "${D}/usr/bin/"
}

