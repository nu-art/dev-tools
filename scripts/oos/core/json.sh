#!/bin/bash

function jsonSerialize() {
    local instance=${1}
    local instanceClass=`${instance}.__class`
    local members=(`${instanceClass}.members`)
    local json="{"

    local i=0
    for (( i = 0; i < ${#members[@]}; ++i )); do
        local member=${members[i]}
        local value=`${instance}.${member}`
        [[ ! ${value} ]] && continue

        value=`echo "${value}" | sed -E 's/"/\\\"/g'`

        json="${json}\"${member}\":\"${value}\""
        (( i < ${#members[@]} -1 )) && json="${json},"
    done
    json="${json}}"
#    json=`echo "${json}" | sed -E 's/"/\\\"/g'`

    echo "${json}"
}