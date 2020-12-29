#!/bin/bash

source ${BASH_SOURCE%/*}/../../_core-tools/_source.sh

string_replaceAll . "@nu-art/storm/server" "@nu-art/thunderstorm/backend" node_modules dist dist-test .idea .stuff .trash .fork .firebase .config dev-tools ts-common testelot thunderstorm firebase .git
string_replaceAll . "@nu-art/storm/firebase" "@nu-art/firebase/backend" node_modules dist dist-test .idea .stuff .trash .fork .firebase .config dev-tools ts-common testelot thunderstorm firebase .git
string_replaceAll . "\"@nu-art/thunder\":" "\"@nu-art/thunderstorm\":" node_modules dist dist-test .idea .stuff .trash .fork .firebase .config dev-tools ts-common testelot thunderstorm firebase .git
string_replaceAll . "from \"@nu-art/thunder\"" "from \"@nu-art/thunderstorm/frontend\"" node_modules dist dist-test .idea .stuff .trash .fork .firebase .config dev-tools ts-common testelot thunderstorm firebase .git
string_replaceAll . "\"@nu-art/firebase-functions\"" "\"@nu-art/firebase/functions\"" node_modules dist dist-test .idea .stuff .trash .fork .firebase .config dev-tools ts-common testelot thunderstorm firebase .git
