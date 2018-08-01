#!/bin/bash
#
# Script to generate Mozilla Firefox test files
# Requires a 32-bit or 64-bit version of Ubuntu 14.04
#
# Reference of Mozilla Firefox command line options:
# https://developer.mozilla.org/en-US/docs/Mozilla/Command_Line_Options
#
# Repositories of older versions of Mozilla Firefox:
# https://ftp.mozilla.org/pub/firefox/releases/

EXIT_SUCCESS=0;
EXIT_FAILURE=1;

FIREFOX_FLAGS="";

PLASO_MSI="plaso-20190429.1.win32.msi";

test_firefox()
{
	local VERSION=$1;
	local MACHINE=$2;

	local URL="https://ftp.mozilla.org/pub/firefox/releases/${VERSION}/linux-${MACHINE}/en-US/firefox-${VERSION}.tar.bz2";

	wget -O "firefox-${VERSION}.tar.bz2" "${URL}";

	# Remove Mozilla Firefox.
	rm -rf firefox;

	# Remove cache and config directories.
	rm -rf "${HOME}/.cache/mozilla/firefox";
	rm -rf "${HOME}/.mozilla/firefox";

	# Install Google Chrome.
	tar jxfv "firefox-${VERSION}.tar.bz2";

	rm -f "firefox-${VERSION}.tar.bz2";

	# TODO: disable default browser check.

	firefox/firefox --version;

	# Run actions to create test data.
	firefox/firefox --new-window --search "plaso log2timeline" &
	firefox/firefox --new-tab ${FIREFOX_FLAGS} https://raw.githubusercontent.com/dfirlabs/firefox-specimens/master/generate-specimens.sh &

	sleep 8;

	kill -15 `pgrep firefox | tr '\n' ' '` &>/dev/null;

	sleep 2;

	kill -9 `pgrep firefox | tr '\n' ' '` &>/dev/null;

	PROFILE_PATH=`ls -1d ${HOME}/.mozilla/firefox/*.default`;

	cat >${PROFILE_PATH}/user.js <<EOT
// Do not ask for confirmation when downloading binary data.
user_pref("browser.helperApps.neverAsk.saveToDisk","application/octet-stream");
EOT

	firefox/firefox ${FIREFOX_FLAGS} https://raw.githubusercontent.com/log2timeline/l2tbinaries/master/win32/${PLASO_MSI} &

	sleep 8;

	kill -15 `pgrep firefox | tr '\n' ' '` &>/dev/null;

	sleep 2;

	kill -9 `pgrep firefox | tr '\n' ' '` &>/dev/null;

	rm -f "${HOME}/Downloads/${PLASO_MSI}";

	# Preserve specimens.
	if ! test -d "specimens";
	then
		mkdir "specimens";
	fi
	tar Jcfv "specimens/firefox-${VERSION}.tar.xz" "${HOME}/.mozilla/firefox" "${HOME}/.cache/mozilla/firefox";

	return ${EXIT_SUCCESS};
}

MACHINE=`uname -m`;

if test "${MACHINE}" != "i686" && test "${MACHINE}" != "x86_64";
then
	echo "Unsupported architecture: ${MACHINE}";

	exit ${EXIT_FAILURE};
fi

# Install dependencies.
sudo apt-get install -y libwww-perl

kill -9 `pgrep firefox | tr '\n' ' '` &>/dev/null;

URL="https://ftp.mozilla.org/pub/firefox/releases/";
VERSIONS=`GET ${URL} | grep 'href="/pub/firefox/releases/' | sed 's?^\s*<td><a href="/pub/firefox/releases/[^>]*>??;s?/</a></td>\s*$??' | grep '^[0-9][0-9]*[.][0-9]$' | sort -nr`;

for VERSION in ${VERSIONS};
do
	test_firefox ${VERSION} ${MACHINE};
done

# Remove cache and config directories.
rm -rf "${HOME}/.cache/mozilla/firefox";
rm -rf "${HOME}/.mozilla/firefox";

exit ${EXIT_SUCCESS};

