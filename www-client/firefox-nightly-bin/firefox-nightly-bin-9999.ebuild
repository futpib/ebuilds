# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

MOZ_PN="firefox"

MOZ_FTP_URI="ftp://ftp.mozilla.org/pub/mozilla.org/firefox/nightly/latest-trunk/"

inherit eutils multilib pax-utils fdo-mime gnome2-utils nsplugins

DESCRIPTION="Firefox Web Browser Nightly Build"
HOMEPAGE="http://nightly.mozilla.org/"
RESTRICT="strip mirror"

KEYWORDS="-* ~amd64 ~x86"
SLOT="0"
LICENSE="MPL-2.0 GPL-2 LGPL-2.1"
IUSE="startup-notification"

DEPEND="app-arch/unzip"
RDEPEND="dev-libs/dbus-glib
	virtual/freedesktop-icon-theme
	x11-libs/libXrender
	x11-libs/libXt
	x11-libs/libXmu

	>=x11-libs/gtk+-2.2:2
	>=media-libs/alsa-lib-1.0.16

	!net-libs/libproxy[spidermonkey]
"

src_unpack() {
	arch='i686'
	if use amd64; then
		arch='x86_64'
	fi
	latest=$(
		curl --silent --list-only "$MOZ_FTP_URI" \
			| grep -E "^firefox-[0-9a-z\.]+\.en-US\.linux-$arch\.tar\.bz2$" \
			| tail -n 1
	)
	elog "Latest version is $latest"
	wget -c "$MOZ_FTP_URI/$latest" -O "${T}/$latest"
	mkdir -p "${S}"
	tar xjvf "${T}/$latest" --directory "${S}" --transform 's|firefox/||' firefox
}

src_install() {
	declare MOZILLA_FIVE_HOME=/opt/${MOZ_PN}

	local size sizes icon_path icon name
	sizes="16 32 48"
	icon_path="${S}/browser/chrome/icons/default"
	icon="${PN}"
	name="Mozilla Firefox"

	# Install icons and .desktop for menu entry
	for size in ${sizes}; do
		insinto "/usr/share/icons/hicolor/${size}x${size}/apps"
		newins "${icon_path}/default${size}.png" "${icon}.png" || die
	done
	# The 128x128 icon has a different name
	insinto "/usr/share/icons/hicolor/128x128/apps"
	newins "${icon_path}/../../../icons/mozicon128.png" "${icon}.png" || die
	# Install a 48x48 icon into /usr/share/pixmaps for legacy DEs
	newicon "${S}"/browser/chrome/icons/default/default48.png ${PN}-icon.png
	domenu "${FILESDIR}"/${PN}.desktop
	sed -i -e "s:@NAME@:${name}:" -e "s:@ICON@:${icon}:" \
		"${ED}/usr/share/applications/${PN}.desktop" || die

	# Add StartupNotify=true bug 237317
	if use startup-notification; then
		echo "StartupNotify=true" >> "${D}"/usr/share/applications/${PN}.desktop
	fi

	# Install firefox in /opt
	dodir ${MOZILLA_FIVE_HOME%/*}
	mv "${S}" "${D}"${MOZILLA_FIVE_HOME} || die

	# Fix prefs that make no sense for a system-wide install
	insinto ${MOZILLA_FIVE_HOME}/defaults/pref/
	doins "${FILESDIR}"/local-settings.js
	insinto ${MOZILLA_FIVE_HOME}/
	doins "${FILESDIR}"/all-gentoo.js

	local LANG=${linguas%% *}
	if [[ -n ${LANG} && ${LANG} != "en" ]]; then
		elog "Setting default locale to ${LANG}"
		echo "pref(\"general.useragent.locale\", \"${LANG}\");" \
			>> "${D}${MOZILLA_FIVE_HOME}"/defaults/pref/${PN}-prefs.js || \
			die "sed failed to change locale"
	fi

	# Create /usr/bin/firefox-bin
	dodir /usr/bin/
	cat <<-EOF >"${D}"/usr/bin/${PN}
	#!/bin/sh
	unset LD_PRELOAD
	LD_LIBRARY_PATH="/opt/firefox/"
	GTK_PATH=/usr/lib/gtk-2.0/
	exec /opt/${MOZ_PN}/${MOZ_PN} "\$@"
	EOF
	fperms 0755 /usr/bin/${PN}

	# revdep-rebuild entry
	insinto /etc/revdep-rebuild
	doins "${FILESDIR}"/10${PN} || die

	# Plugins dir
	share_plugins_dir

	# Required in order to use plugins and even run firefox on hardened.
	pax-mark mr "${ED}"/${MOZILLA_FIVE_HOME}/{firefox,firefox-nightly-bin,plugin-container}
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	if ! has_version 'gnome-base/gconf' || ! has_version 'gnome-base/orbit' \
		|| ! has_version 'net-misc/curl'; then
		einfo
		einfo "For using the crashreporter, you need gnome-base/gconf,"
		einfo "gnome-base/orbit and net-misc/curl emerged."
		einfo
	fi
	# Drop requirement of curl not built with nss as it's not necessary anymore
	#if has_version 'net-misc/curl[nss]'; then
	#	einfo
	#	einfo "Crashreporter won't be able to send reports"
	#	einfo "if you have curl emerged with the nss USE-flag"
	#	einfo
	#fi

	# Update mimedb for the new .desktop file
	fdo-mime_desktop_database_update
	gnome2_icon_cache_update
}

pkg_postrm() {
	gnome2_icon_cache_update
}
