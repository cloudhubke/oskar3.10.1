set -xg COMMUNITY_DOWNLOAD_LINK "https://community.arangodb.com"
set -xg ENTERPRISE_DOWNLOAD_LINK "https://enterprise.arangodb.com"

# set -xg DOWNLOAD_SYNC_USER "exampleUser"

set -gx USE_CCACHE "sccache"
set -gx NOTARIZE_USER "exampleUser"
set -gx NOTARIZE_PASSWORD "examplePassword"
set -gx MACOS_ADMIN_KEYCHAIN_PASS "-"