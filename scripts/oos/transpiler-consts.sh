#!/bin/bash
OOS_TranspileConst_ClassName=__ClassName__
OOS_TranspileConst_StaticId=__StaticId__
OOS_TranspileConst_Name=__Name__


#OOS_TranspileConst_InstanceName=__InstanceName__
#OOS_TranspileConst_PropertyWithGetterAndSetter="
#    local InstanceId_${OOS_TranspileConst_Name}=
#    function ${OOS_TranspileConst_InstanceName}.${OOS_TranspileConst_Name}() {
#        if [[ \"\\$1\" == \"=\" ]]; then
#            ${OOS_TranspileConst_ClassName}.property ${OOS_TranspileConst_Name} = \"\\$2\"
#        else
#            ${OOS_TranspileConst_ClassName}.property ${OOS_TranspileConst_Name}
#        fi
#    }"
#
#OOS_TranspileConst_Create="
#function create() {
#    ${OOS_TranspileConst_ClassName}.property() {
#        if [[ \"\\$2\" == \"=\" ]]; then
#            setVariableName ${OOS_TranspileConst_ClassName}_\\$1 \"\\$3\"
#        else
#            local temp=${OOS_TranspileConst_ClassName}_\\${1}
#            echo \"\\${!temp}\";
#        fi
#    }"

OOS_TranspileConst_PropertyWithGetterAndSetter_Naive="local ${OOS_TranspileConst_ClassName}_${OOS_TranspileConst_Name}=
    function ${OOS_TranspileConst_ClassName}.${OOS_TranspileConst_Name}() {
        if [[ \"\$1\" == \"=\" ]]; then
            ${OOS_TranspileConst_ClassName}_${OOS_TranspileConst_Name}=\"\$2\"
        else
            echo \"\${${OOS_TranspileConst_ClassName}_${OOS_TranspileConst_Name}}\"
        fi
    }"


