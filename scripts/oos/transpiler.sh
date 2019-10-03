#!/bin/bash
source ./transpiler-consts.sh

new (){
    local className=${1}
    local instanceName=${2}

    local class=$(cat ${className}.class.sh)
    local defaultValues=$(transpile_GetMembersDefaultValues ${instanceName} "${class}")

    class=$(transpile_Class ${className} "${class}")
    class=$(echo -e "${class}" | sed -E "s/${className}/${instanceName}/g")

#    echo -e "${class}"
    . <(echo -e "${class}")

    ${instanceName}
    ${defaultValues}
}


transpile_Class() {
    local className=${1}
    local class="${2}"

    class=$(transpile_AllMembers ${className} "${class}")
    class=$(transpile_AllMethods ${className} "${class}")

    echo -e "${class}"
}

transpile_GetMembersDefaultValues() {
    echo "$(echo -e "${2}" | grep -E "declare.*=.+$" | sed -E "s/declare ([a-zA-Z_]{1,})=(.*)$/${1}.\1 = \2/g")"
}

transpile_GetMemberNames() {
    echo "$(echo -e "${1}" | grep -E "declare .*" | sed -E "s/.*declare ([a-zA-Z_]{1,}).*$/\1/g")"
}

transpile_AllMembers() {
    local className=${1}
    local class="${2}"

    local members=(`transpile_GetMemberNames "${class}"`)
    for member in "${members[@]}"; do
        class=$(echo -e "${class}" | sed -E "s/\\$\{${member}\}/\${${className}_${member}}/g")
    done

    class=$(echo -e "${class}" | sed -E "s/declare ([a-zA-Z_]{1,})=.*$/declare \1/g")
    class=$(echo -e "${class}" | sed -E "s/declare ([a-zA-Z_]{1,})$/`transpile_Member ${className} \"\\\\\1\"`/g")

    echo -e "${class}"
}

transpile_Member() {
    local className=${1}
    local memberName=${2}
    local defaultValue=${3}

    local method="${OOS_TranspileConst_PropertyWithGetterAndSetter_Naive}"
    method=`echo "${method}" | sed -E "s/${OOS_TranspileConst_ClassName}/${className}/g"`
    method=`echo "${method}" | sed -E "s/${OOS_TranspileConst_Name}/${memberName}/g"`

    echo "${method//$'\n'/'\\n'}"
}

transpile_GetMethodsNames() {
    echo "$(echo -e "${1}" | grep -E ".*_.*() ?\{$" | sed -E "s/.*_([a-zA-Z_]{1,})\(\) ?\{$/\1/g")"
}

transpile_AllMethods() {
    local className=${1}
    local class="${2}"

    local methods=(`transpile_GetMethodsNames "${class}"`)
    for method in "${methods[@]}"; do
        class=$(echo -e "${class}" | sed -E "s/_${method}\(\)/${className}.${method}()/g")
    done

    echo -e "${class}"
}

