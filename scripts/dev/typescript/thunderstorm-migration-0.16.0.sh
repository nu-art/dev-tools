#!/bin/bash

source ${BASH_SOURCE%/*}/../../_core-tools/_source.sh

replaceStringInFiles . "@nu-art/storm/server" "@nu-art/thunderstorm/backend" node_modules dist dist-test .idea .stuff .trash .fork .firebase .config dev-tools ts-common testelot thunderstorm firebase .git
replaceStringInFiles . "@nu-art/storm/firebase" "@nu-art/firebase/backend" node_modules dist dist-test .idea .stuff .trash .fork .firebase .config dev-tools ts-common testelot thunderstorm firebase .git
replaceStringInFiles . "\"@nu-art/thunder\":" "\"@nu-art/thunderstorm\":" node_modules dist dist-test .idea .stuff .trash .fork .firebase .config dev-tools ts-common testelot thunderstorm firebase .git
replaceStringInFiles . "from \"@nu-art/thunder\"" "from \"@nu-art/thunderstorm/frontend\"" node_modules dist dist-test .idea .stuff .trash .fork .firebase .config dev-tools ts-common testelot thunderstorm firebase .git
replaceStringInFiles . "\"@nu-art/firebase-functions\"" "\"@nu-art/firebase/functions\"" node_modules dist dist-test .idea .stuff .trash .fork .firebase .config dev-tools ts-common testelot thunderstorm firebase .git
