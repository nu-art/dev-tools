#!/bin/bash
OOS_TranspileConst_ClassName=__ClassName__
OOS_TranspileConst_StaticId=__StaticId__
OOS_TranspileConst_Name=__Name__


OOS_TranspileConst_PrimitiveMemberWithGetterAndSetter="local ${OOS_TranspileConst_ClassName}_${OOS_TranspileConst_Name}=
    ${OOS_TranspileConst_ClassName}.${OOS_TranspileConst_Name}() {
        if [[ \"\$1\" == \"=\" ]]; then
            ${OOS_TranspileConst_ClassName}_${OOS_TranspileConst_Name}=\"\$2\"
        else
            echo \"\${${OOS_TranspileConst_ClassName}_${OOS_TranspileConst_Name}}\"
        fi
    }
    "

OOS_TranspileConst_ArrayMemberWithGetterAndSetter="local ${OOS_TranspileConst_ClassName}_${OOS_TranspileConst_Name}=()
    "


