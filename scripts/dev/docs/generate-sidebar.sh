#!/bin/bash

source ../dev-tools/scripts/_core-tools/_source.sh

getFolders() {
    local folders=($(ls -l1 -d */ ))
    echo "${folders[@]}"
}

getMDFiles() {
    local files=($(ls -l1 *.md 2>/dev/null))
    echo "${files[@]}"
}

createSidebar() {
    local allFileFullPaths=()
    local allFileNames=()

    local output="[Home](Home)\n"
    local counter=1
    append() {
        local toAppend=${1}
        output="${output}${toAppend}\n"
    }

    local folders=(`getFolders`)
    for folder in "${folders[@]}"; do
        local _folder=$(echo "${folder}" | sed -E "s/[0-9]+-(.*)/\1/")
        _folder="${_folder::-1}"
        _cd "${folder}"
            local files=($(getMDFiles))
            if (( "${#files}" > 0 )); then
                append "${counter}. ${_folder^}"
                ((counter++))
            fi
            for mdFile in "${files[@]}"; do
                allFileFullPaths+=("./${folder}${mdFile}")
                allFileNames+=("${mdFile}")
                local firstLine=$(cat "${mdFile}" | head -1)
                if [[ ! "${firstLine}" =~ "# " ]]; then
                    firstLine="# NO-INPUT"
                    logWarning "Missing title input for: ${mdFile}"
                fi

                if [[ "${mdFile}" =~ "__" ]]; then continue; fi
                append "    * [${firstLine:2}](${mdFile::-3})"
            done
        cd ..
    done

    for file in "${allFileFullPaths[@]}"; do
#    echo cat ${file}
        local links=($(cat ${file} | grep -o '\[.*\]: .*' | sed -E "s/.*: (.*)/\1/"))
        local links2=($(cat ${file} | grep -o '\[.*\](.*)' | sed -E "s/.*\((.*)\)/\1/"))
        links+=("${links2[@]}")
        local hasBadLinks=
        for link in "${links[@]}"; do
            if [[ "${link}" =~ "http" ]]; then
                continue
            fi

            if [[ "${link}" =~ .. ]]; then
                continue
            fi

            if [[ $(array_contains "${link}.md" "${allFileNames[@]}") ]]; then
                continue
            fi

            if [[ ! "${hasBadLinks}" ]]; then logVerbose; logError "Error in file: ${file}"; fi
            hasBadLinks=true
            logDebug " - Found bad wiki ref: ${file} -> ${link}"
        done
    done

    echo -e "${output}" > _Sidebar.md
}
