#!/bin/bash
# This script expects the clipboard to contain the path to the app to be packaged for release
# I have a build script setup which copies the path when building a release.

# TODO : Correctly support beta release
#	 Make generic for use with any app

APP_NAME="Optimal Layout.app"
APP_VERSIONS_DIR="${HOME}/Releases/"
DEPLOY_SCRIPT_PATH="${HOME}/Dropbox/Dev/Optimal Layout/deploy-update.sh"
DEPLOY_SERVER="user@domain.com" # the ssh user and server to deploy to
APP_DIR=`pbpaste`
APP_VERSION=`defaults read ${APP_DIR}/Optimal\ Layout.app/Contents/Info CFBundleVersion`
APP_VERSION_SHORT=`defaults read ${APP_DIR}/Optimal\ Layout.app/Contents/Info CFBundleShortVersionString`
APP_MIN_SYS_VERSION=`defaults read ${APP_DIR}/Optimal\ Layout.app/Contents/Info LSMinimumSystemVersion`
ZIP_NAME="OptimalLayout2-${APP_VERSION}.zip"
ZIP_LOCAL_PATH="${APP_VERSIONS_DIR}${ZIP_NAME}"
ZIP_SERVER_PATH="/var/www/files.windowflow.com/"
PRIVATE_KEY_PATH="${HOME}/Releases/dsa_priv.pem"
PUB_DATE=$(date +"%a, %d %b %G %T %z")

RELEASE_NOTES_NAME="ReleaseNotes-${APP_VERSION}.html"
APPCAST_NAME="OL-AppCast.xml"
if [ "$1" = "BETA" ]
then
	APPCAST_NAME="OL2-Beta-AppCast.xml"
	RELEASE_NOTES_NAME="ReleaseNotest-${APP_VERSION}-Beta.html"
fi

APPCAST_URL="http://most-advantageous.com/AppCasts/${APPCAST_NAME}"
APPCAST_LOCAL_PATH="${HOME}/Dropbox/Dev/www/most-advantageous.com/AppCasts/${APPCAST_NAME}"
APPCAST_SERVER_PATH="/var/www/most-advantageous.com/AppCasts/${APPCAST_NAME}"

RELEASE_NOTES_LOCAL_PATH="${HOME}/Dropbox/Dev/www/most-advantageous.com/AppCasts/OL-release-notes/${RELEASE_NOTES_NAME}"
RELEASE_NOTES_SERVER_PATH="/var/www/most-advantageous.com/AppCasts/OL-release-notes/"
RELEASE_NOTES_URL="http://most-advantageous.com/AppCasts/OL-release-notes/${RELEASE_NOTES_NAME}"

pushd "$(pbpaste)"
zip -qyr $ZIP_LOCAL_PATH "$APP_NAME"
ZIP_SIZE=`ls -al ${ZIP_PATH} | awk '{ print $5 }'`

ECHO "Created ${ZIP_LOCAL_PATH}"

pushd $APP_VERSIONS_DIR

SIGNATURE=`openssl dgst -sha1 -binary < "${ZIP_LOCAL_PATH}" | openssl dgst -dss1 -sign "${PRIVATE_KEY_PATH}" | openssl enc -base64`

cat <<_EOF_> "${APPCAST_LOCAL_PATH}" 
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"  xmlns:dc="http://purl.org/dc/elements/1.1/">
<channel>
<title>Optimal Layout's Changelog</title>
<link>${APPCAST_URL}</link>
<description>Most recent changes with links to updates.</description>
<language>en</language>
<item>
<title>Version ${APP_VERSION_SHORT}</title>
<sparkle:minimumSystemVersion>${APP_MIN_SYS_VERSION}</sparkle:minimumSystemVersion>
<sparkle:releaseNotesLink>${RELEASE_NOTES_URL}</sparkle:releaseNotesLink>
<pubDate>${PUB_DATE}</pubDate>
<enclosure url="http://files.windowflow.com/${ZIP_NAME}" 
	sparkle:version="${APP_VERSION}"
	sparkle:shortVersionString="${APP_VERSION_SHORT}"
	sparkle:dsaSignature="${SIGNATURE}"
	length="${ZIP_SIZE}"
	type="application/octet-stream" />
</item>
</channel>
</rss>
_EOF_

touch ${RELEASE_NOTES_LOCAL_PATH}

cat <<_EOF_> "${DEPLOY_SCRIPT_PATH}"
scp ${ZIP_LOCAL_PATH} ${DEPLOY_SERVER}:${ZIP_SERVER_PATH}
scp ${APPCAST_LOCAL_PATH} ${DEPLOY_SERVER}:${APPCAST_SERVER_PATH} 
scp ${RELEASE_NOTES_LOCAL_PATH} ${DEPLOY_SERVER}:${RELEASE_NOTES_SERVER_PATH}
ssh ${DEPLOY_SERVER} "cp ${ZIP_SERVER_PATH}${ZIP_NAME} ${ZIP_SERVER_PATH}OptimalLayout2.zip"
ssh ${DEPLOY_SERVER} "cp ${ZIP_SERVER_PATH}${ZIP_NAME} ${ZIP_SERVER_PATH}OptimalLayout.zip"

# pushd ${APPCAST_LOCAL_PATH}
# git add .
# git commit -am "${APP_VERSION} ${APP_VERSION_SHORT} Release"

# pushd $(dirname $0)
# git commit -am "${APP_VERSION} ${APP_VERSION_SHORT} Release"

_EOF_

chmod +x "${DEPLOY_SCRIPT_PATH}"
ECHO "Write release notes to ${RELEASE_NOTES_LOCAL_PATH}"
ECHO "Then deploy with:"
ECHO $DEPLOY_SCRIPT_PATH
