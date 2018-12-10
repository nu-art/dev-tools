#!/usr/bin/env bash


source ${BASH_SOURCE%/*}/../utils/coloring.sh
printedSignature=
function signature() {
    local scriptName=${1}
    if [ "${scriptName}" == "" ]; then
        scriptName=`echo "${0}" | sed -E "s/.*\/(.*)\.sh/\1/"`
    fi

    if [ "${printedSignature}" ]; then
        return
    fi

    printedSignature="true"

    clear
    echo
    echo -e " '${Red}${scriptName}${NoColor}' Script Made by:${Gray} ";
    echo
    printSig2
    echo -e " ${NoColor}"
    sleep 2s
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