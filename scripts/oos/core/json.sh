#!/bin/bash

function jsonSerialize() {
    local instance=${1}
    local members=(${@:2})
    local instanceClass=`${instance}.__class`
    local classMembers=(`${instanceClass}.members`)

    (( ${#members[@]} == 0 )) && members=(${classMembers[@]})

    local i=0
    local json="{"
    for (( i = 0; i < ${#members[@]}; ++i )); do
        local member=${members[i]}

        [[ ! `contains ${member} ${classMembers[@]}` ]] && throwError "Cannot serialize a property that is not defined in class: ${instanceClass}" 3

        local value=`${instance}.${member}`
        [[ ! ${value} ]] && continue

        [[ ! `isFunction ${value}.__class` ]] && value=`jsonSerialize ${value}`

        [[ "${value:0:1}" != "{" ]] || [[ "${value: -1}" != "}" ]] && value=`echo "${value}" | sed -E 's/"/\\\"/g'` && value="\"${value}\""
#        _logInfo "${value}"
        json="${json}\"${member}\":${value}"
        (( i < ${#members[@]} -1 )) && json="${json},"
    done
    json="${json}}"
#    json=`echo "${json}" | sed -E 's/"/\\\"/g'`

    echo "${json}"
}