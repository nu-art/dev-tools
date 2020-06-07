#!/bin/bash
OOS_TranspileConst_ClassName=__ClassName__
OOS_TranspileConst_StaticId=__StaticId__
OOS_TranspileConst_Name=__Name__

OOS_TranspileConst_PrimitiveMemberWithGetterAndSetter="
    local ${OOS_TranspileConst_ClassName}_${OOS_TranspileConst_Name}=
    ${OOS_TranspileConst_ClassName}.${OOS_TranspileConst_Name}() {
        if [[ \"\$1\" == \"=\" ]]; then
            ${OOS_TranspileConst_ClassName}_${OOS_TranspileConst_Name}=\"\$2\"
        else
            echo \"\${${OOS_TranspileConst_ClassName}_${OOS_TranspileConst_Name}}\"
        fi
    }
    "

OOS_TranspileConst_ArrayMemberWithGetterAndSetter="
    local ${OOS_TranspileConst_ClassName}_${OOS_TranspileConst_Name}=()
    ${OOS_TranspileConst_ClassName}.${OOS_TranspileConst_Name}() {
        if [[ \"\$1\" == \"=\" ]]; then
            ${OOS_TranspileConst_ClassName}_${OOS_TranspileConst_Name}=(\"\${@:2}\")
        elif [[ ! \"\$1\" ]]; then
            echo \"\${${OOS_TranspileConst_ClassName}_${OOS_TranspileConst_Name}[@]}\"
        else
            number_assertNumeric \"\$1\"
            echo \"\${${OOS_TranspileConst_ClassName}_${OOS_TranspileConst_Name}[\$1]}\"
        fi
    }

    ${OOS_TranspileConst_ClassName}.${OOS_TranspileConst_Name}.length() {
        echo \"\${#${OOS_TranspileConst_ClassName}_${OOS_TranspileConst_Name}[@]}\"
    }

    ${OOS_TranspileConst_ClassName}.${OOS_TranspileConst_Name}.forEach() {
        local command=\${1}
        [[ ! \"\${command}\" ]] \&\& throwError \"No command spcified\" 2
        for item in \${${OOS_TranspileConst_ClassName}_${OOS_TranspileConst_Name}[@]}; do
          \"\${item}.\${command}\" \${@:2}
        done
    }
    "
