#
#  This file is a part of nu-art projects development tools,
#  it has a set of bash and gradle scripts, and the default
#  settings for Android Studio and IntelliJ.
#
#     Copyright (C) 2017  Adam van der Kruk aka TacB0sS
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#          You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

#!/usr/bin/env bash

printedSignature=
function signature() {
    local scriptName=${1}
    if [[ ! "${scriptName}" ]]; then
        scriptName=`echo "${0}" | sed -E "s/.*\/(.*)\.sh/\1/"`
    fi

    if [[ "${printedSignature}" ]]; then
        return
    fi

    printedSignature="true"

#    clear
    echo
    echo -e " Script: '${Red}${scriptName}${NoColor}'";
    echo -e " License: '${Red}Apache v2.0${NoColor}'";
    echo
    printSig2
    echo -e " ${NoColor}"
}

function printSig1() {
    echo -e "MMP\"\"MM\"\"YMM            \`7MM\"\"\"Yp,                     .M\"\"\"bgd ";
    echo -e "P'   MM   \`7              MM    Yb                    ,MI    \"Y ";
    echo -e "     MM   ,6\"Yb.  ,p6\"bo  MM    dP  ,pP\"\"Yq.  ,pP\"Ybd \`MMb.     ";
    echo -e "     MM  8)   MM 6M'  OO  MM\"\"\"bg. 6W'    \`Wb 8I   \`\"   \`YMMNq. ";
    echo -e "     MM   ,pm9MM 8M       MM    \`Y 8M      M8 \`YMMMa. .     \`MM ";
    echo -e "     MM  8M   MM YM.    , MM    ,9 YA.    ,A9 L.   I8 Mb     dM ";
    echo -e "   .JMML.\`Moo9^Yo.YMbmd'.JMMmmmd9   \`Ybmmd9'  M9mmmP' P\"Ybmmd\"";
}

function printSig2() {
    echo -e ",--------.             ,-----.    ,--.          ,---.   ";
    echo -e "'--.  .--',--,--. ,---.|  |) /_  /    \  ,---. '   .-'  ";
    echo -e "   |  |  ' ,-.  || .--'|  .-.  \|  ()  |(  .-' \`.  \`-.  ";
    echo -e "   |  |  \ '-'  |\ \`--.|  '--' / \    / .-'  \`).-'    | ";
    echo -e "   \`--'   \`--\`--' \`---'\`------'   \`--'  \`----' \`-----'  ";
}