#!/bin/bash

jsonSerialize() {
    local instance=${1}
    local members=(${@:2})
    local instanceClass=`${instance}.__class`
    local classMembers=(`${instanceClass}.members`)

    (( ${#members[@]} == 0 )) && members=(${classMembers[@]})

    local memberIndex=0
    local json="{"
    for (( memberIndex = 0; memberIndex < ${#members[@]}; ++memberIndex )); do
        local member=${members[memberIndex]}

        [[ ! `array_contains ${member} ${classMembers[@]}` ]] && throwError "Cannot serialize a property that is not defined in class: ${instanceClass}" 3

        local value=`${instance}.${member}`
        [[ ! ${value} ]] && continue

        [[ `isFunction ${value}.__class` ]] && value=`jsonSerialize ${value}`

        [[ "${value:0:1}" != "{" ]] || [[ "${value: -1}" != "}" ]] && value=`echo "${value}" | sed -E 's/"/\\\"/g'` && value="\"${value}\""
#        _logInfo "${value}"
        json="${json}\"${member}\":${value}"
        (( memberIndex < ${#members[@]} -1 )) && json="${json},"
    done
    json="${json}}"
#    json=`echo "${json}" | sed -E 's/"/\\\"/g'`

    echo "${json}"
}