#!/bin/bash
source ./transpiler-consts.sh

new (){
    local className=${1}
    local instanceName=${2}

    local classFile=$(cat ${className}.class.sh)
    classFile=$(echo -e "${classFile}" | sed -E "s/class_LogEntry/create/g")

    local defaultValues=$(echo -e "${classFile}" | grep -E "declare.*=.+?" | sed -E "s/declare ([a-zA-Z_]{1,})=(.*)$/${instanceName}.\1 = \2/g")
    classFile=$(echo -e "${classFile}" | sed -E "s/declare ([a-zA-Z_]{1,})=.*$/declare \1/g")
    classFile=$(echo -e "${classFile}" | sed -E "s/declare ([a-zA-Z_]{1,})$/`transpile_Member ${instanceName} \"\\\\\1\"`/g")
    classFile=$(echo -e "${classFile}" | sed -E "s/${className}/${instanceName}/g")
#    echo -e "${classFile}"

    . <(echo -e "${classFile}")
    create
    ${defaultValues}
}


transpile_Member() {
    local instanceId=${1}
    local memberName=${2}
    local defaultValue=${3}
    local method="${OOS_TranspileConst_PropertyWithGetterAndSetter_Naive}"
    method=`echo "${method}" | sed -E "s/${OOS_TranspileConst_DefaultValue}/${defaultValue}/g"`
    method=`echo "${method}" | sed -E "s/${OOS_TranspileConst_InstanceId}/${instanceId}/g"`
    method=`echo "${method}" | sed -E "s/${OOS_TranspileConst_Name}/${memberName}/g"`
    echo "${method//$'\n'/'\\n'}"
}
