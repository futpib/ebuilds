
EAPI=4

DESCRIPTION="Linux capture program for the Somagic variants of the EasyCAP"
HOMEPAGE="https://code.google.com/p/easycap-somagic-linux/"
SRC_URI="https://easycap-somagic-linux.googlecode.com/files/${PN}_${PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 x86"

RDEPEND="virtual/libusb
	dev-libs/libgcrypt"
DEPEND="${RDEPEND}"

src_unpack() {
	unpack ${A}
	mv "${WORKDIR}/${PN}_${PV}" "${S}"
}

src_install() {
	emake PREFIX="${D}" install
}
