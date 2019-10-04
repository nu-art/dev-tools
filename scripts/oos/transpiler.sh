#!/bin/bash
source ./transpiler-consts.sh
source ./transpiler-logs.sh

#CONST_Debug=true

new (){
    local className=${1}
    local instanceName=${2}
    fqn=Class_${className}

    _logDebug "new ${className} ${instanceName}"

    loadClass ${className} ${instanceName}

    local class=$(${fqn}.rawClass)
    local defaultValues=$(${fqn}.defaultValues)

    class=$(echo -e "${class}" | sed -E "s/${className}/${instanceName}/g")
    defaultValues=$(echo -e "${defaultValues}" | sed -E "s/${className}/${instanceName}/g")

    . <(echo -e "${class}")
    if [[ "${className}" == "ClassObj" ]]; then
        return
    fi

    ${instanceName}
    ${defaultValues}

}

loadClass() {
    local className=${1}
    local instanceName=${2}
    _logInfo "loadClass: className=${className}, instanceName=${instanceName}"

    fqn=Class_${className}
    local class=
    local members=
    local methods=
    local defaultValues=
    if [[ `type -t "${fqn}.rawClass"` != 'function' ]]; then
        _logError "Loading class from file: ${className} for instance: ${instanceName}"
        class=$(cat ${className}.class.sh)
        members=(`transpile_GetMemberNames "${class}"`)
        methods=(`transpile_GetMethodsNames "${class}"`)
        defaultValues=$(transpile_GetMembersDefaultValues ${className} "${class}")
        class=$(transpile_Class ${className} "${class}")

        if [[ "${fqn}" == "Class_ClassObj" ]]; then
            class=$(echo -e "${class}" | sed -E "s/ClassObj/${fqn}/g")

#            _logWarning "Here 1"
#            _logWarning "Class: ${class}"

            . <(echo -e "${class}")
        else
            _logWarning "Here 2"
            new ClassObj ${className}
            local rawClass="`Class_ClassObj.rawClass`"
            rawClass=$(echo -e "${rawClass}" | sed -E "s/ClassObj/${className}/g")
#            _logWarning "rawClass: ${rawClass}"

            . <(echo -e "${rawClass}")
        fi

        ${fqn}
        ${fqn}.rawClass = "${class}"
        ${fqn}.defaultValues = "${defaultValues}"
        ${fqn}.members = "`echo "${members[@]}"`"
        ${fqn}.methods = "`echo "${methods[@]}"`"
    else
        class="`${fqn}.rawClass`"
    fi

##    _logDebug "found defaultValues: ${defaultValues}"
#
#    if [[ "${className}" == "ClassObj" ]] && [[ "${instanceName}" == "Class_ClassObj" ]] ; then
#        _logWarning "Creating a new Class instance for: ${className}"
#    else
#        _logInfo "Creating a new Class instance for: ${className} ${classInstanceName}"
#        new ClassObj ${classInstanceName}
#    fi
#
#    _logInfo "Setting class values: ${className}"
#    _logInfo "${classInstanceName}.defaultValues = \"${defaultValues}\""
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