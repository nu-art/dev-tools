#!/usr/bin/env bash



"                _                                      "
"              (\`  ).                   _               "
"             (     ).              .:(\`  )\`.           "
")           _(       '\`.          :(   .    )          "
"        .=(\`(      .   )     .--  \`.  (    ) )         "
"       ((    (..__.:'-'   .+(   )   \` _\`  ) )          "
"\`.     \`(       ) )       (   .  )     (   )  ._       "
"  )      \` __.:'   )     (   (   ))     \`-'.-(\`  )     "
")  )  ( )       --'       \`- __.'         :(      ))   "
".-'  (_.'          .')                    \`(    )  ))  "
"                  (_  )                     \` __.:'    "
"                                                       "
"             _.-._                              _.-._  "
"--..,___.--,/     \-..-.--+--.,,-,,..._.--..-._/     \."



_cloud1() {
  cloud1="   _
 (\`  ).
(      ).
(     (   '\`.
 (   )     .  )
  (..__.:'--''"

}

_cloud2() {
    cloud2="OS    .--
OS   (   )
OS  (   .  )
OS(   (   ))
OS\`- __.'  "
}

_cloud1
_cloud2

animate() {
    local item=${1}
    local x=${2}
    local y=${3}
    local width=${4}
    local height=${5}

    local toX=${5}
    local toY=${5}

    local fromX=${2}
    local toX=${3}
    local fromY=${4}
    local toY=${5}
    local dx=1
    local dy=1

    if (( ${fromX} > ${toX} )); then
        dx=-1
    fi


    for (( arg=${fromX}; arg != ${toX}; arg+=${dx} )); do
        echo "fromX: ${fromX}    toX: ${toX}     progress: ${arg}"
        local replacer=`seq  -f " " -s '' ${arg}`
        local temp=`echo "${item}" | sed -E "s/OS/${replacer}/"`
        echo -e "${temp}"

        if [[ "${arg}" == "${toX}" ]]; then
            break;
        fi

        sleep 0.01
        tput cuu1
        tput cuu1
        tput cuu1
        tput cuu1
        tput cuu1
        tput cuu1
    done
}

animate "${cloud2}" 5 20
animate "${cloud1}" 5 20