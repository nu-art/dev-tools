#!/bin/bash
source ./transpiler-consts.sh

new (){
    local className=${1}
    local instanceName=${2}

    local class=$(cat ${className}.class.sh)
    local defaultValues=$(transpile_DefaultValues ${instanceName} "${class}")
    class=$(transpile_Class ${className} ${instanceName} "${class}")
    class=$(echo -e "${class}" | sed -E "s/${className}/${instanceName}/g")

    echo -e "${class}"
    . <(echo -e "${class}")

    ${instanceName}
    ${defaultValues}
}

transpile_DefaultValues() {
    echo "$(echo -e "${2}" | grep -E "declare.*=.+$" | sed -E "s/declare ([a-zA-Z_]{1,})=(.*)$/${1}.\1 = \2/g")"
}

transpile_GetMembers() {
    echo "$(echo -e "${1}" | grep -E "declare .*" | sed -E "s/.*declare ([a-zA-Z_]{1,}).*$/\1/g")"
}

transpile_Class() {
    local className=${1}
    local instanceName=${2}
    local class="${3}"

    local members=(`transpile_GetMembers "${class}"`)
    for member in "${members[@]}"; do
        class=$(echo -e "${class}" | sed -E "s/\\$\{${member}\}/\${${instanceName}_${member}}/g")
    done

    class=$(echo -e "${class}" | sed -E "s/declare ([a-zA-Z_]{1,})=.*$/declare \1/g")
    class=$(echo -e "${class}" | sed -E "s/declare ([a-zA-Z_]{1,})$/`transpile_Member ${instanceName} \"\\\\\1\"`/g")


    echo -e "${class}"
}

transpile_Member() {
    local instanceId=${1}
    local memberName=${2}
    local defaultValue=${3}

    local method="${OOS_TranspileConst_PropertyWithGetterAndSetter_Naive}"
    method=`echo "${method}" | sed -E "s/${OOS_TranspileConst_InstanceId}/${instanceId}/g"`
    method=`echo "${method}" | sed -E "s/${OOS_TranspileConst_Name}/${memberName}/g"`

    echo "${method//$'\n'/'\\n'}"
}
