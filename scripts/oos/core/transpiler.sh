#!/bin/bash
source ${BASH_SOURCE%/*}/../../_core-tools/_source.sh
source ${BASH_SOURCE%/*}/transpiler-consts.sh

enforceBashVersion 4.4

GLOBAL_TranspilerPaths=("${BASH_SOURCE%/*}")

setTranspilerOutput() {
  local output=
  if [[ "$(string_startsWith "${1}" "./")" ]]; then
    output="$(pwd)$(string_substring "${1}" 1)"
  elif [[ "$(string_startsWith "${1}" "/")" ]]; then
    output=${1}
  else
    output="$(pwd)/${1}"
  fi

  _logInfo "Setting output: ${output}"
  [[ ! -e "${output}" ]] && createDir "${output}"

  GLOBAL_TranspilerOutput="${output}/output"
  createDir "${GLOBAL_TranspilerOutput}" > /dev/null

  GLOBAL_TranspilerOutputClasses="${GLOBAL_TranspilerOutput}/classes"
  GLOBAL_TranspilerOutputTemplate="${GLOBAL_TranspilerOutput}/template"
  GLOBAL_TranspilerOutputInstances="${GLOBAL_TranspilerOutput}/instances"

  createDir "${GLOBAL_TranspilerOutputClasses}" > /dev/null
  clearDir "${GLOBAL_TranspilerOutputClasses}" > /dev/null

  createDir "${GLOBAL_TranspilerOutputTemplate}" > /dev/null
  clearDir "${GLOBAL_TranspilerOutputClasses}" > /dev/null

  createDir "${GLOBAL_TranspilerOutputInstances}" > /dev/null
  clearDir "${GLOBAL_TranspilerOutputInstances}" > /dev/null
}

addTranspilerClassPath() {
  _logVerbose "Adding classpath: ${1}"
  GLOBAL_TranspilerPaths[${#GLOBAL_TranspilerPaths[@]}]=${1}
}

new() {
  [[ ! "${GLOBAL_TranspilerOutput}" ]] && setTranspilerOutput "$(pwd)"

  local className=${1}
  local instanceName=${2}
  [[ ! "${instanceName}" ]] && instanceName="i$(string_generateHex 8)"
  local fqn=Class_${className}

  _logVerbose "new ${className} ${instanceName}"
  loadClass "${className}"

  local class=$("${fqn}.class")
  local defaultValues=$("${fqn}.defaultValues")

  class=$(echo -e "${class}" | sed -E "s/${className}/${instanceName}/g")
  defaultValues=$(echo -e "${defaultValues}" | sed -E "s/${className}/${instanceName}/g")

  if [[ "${className}" == "ClassObj" ]]; then
    saveAndSource "${class}" "${GLOBAL_TranspilerOutputClasses}/${className}_${instanceName}.class.sh"
    return
  fi

  saveAndSource "${class}" "${GLOBAL_TranspilerOutputInstances}/${className}_${instanceName}.class.sh"
  echo -e "${class}" > "${GLOBAL_TranspilerOutputInstances}/${className}_${instanceName}.class.sh"

  ${instanceName}
  ${defaultValues}

  "${instanceName}.__this" = "${instanceName}"
  "${instanceName}.__class" = "${fqn}"

  [[ "${2}" ]] && return
  echo "${instanceName}"
}

transpile_AppendParentClasses() {
  local class=${1}

  transpile_parentClass() {
    local parentClass=${1}

    #    _logWarning "extending ${parentClass}"
    loadClass "${parentClass}"

    local parentRawClass="$("Class_${parentClass}.rawClass")"

    local childMethods=($(transpile_GetMethodsNames "${class}"))
    local parentMethods=($(transpile_GetMethodsNames "${parentRawClass}"))
    for method in ${childMethods[@]}; do
      [[ ! "$(array_contains "${method}" ${parentMethods[@]})" ]] && continue
      parentRawClass="$(echo -e "${parentRawClass}" | sed -E "s/_${method}\(\)/_${parentClass}.${method}()/g")"
    done

    local extendsLine=$(echo -e "${class}" | grep -n "extends class ${parentClass}" | head -n 1 | cut -d: -f1)
    local totalLines=$(echo -n "${class}" | grep -c '^')

    local start="$(echo -e "${class}" | sed -n "1,$((extendsLine - 1))p")"
    local end="$(echo -e "${class}" | sed -n "$((extendsLine + 1)),$((totalLines))p")"
    class="${start}\n${parentRawClass}\n${end}"
    echo -e "${class}"
  }

  local parents=($(transpile_GetParentsClasses "${class}"))

  for parentClass in "${parents[@]}"; do
    class=$(transpile_parentClass "${parentClass}")
  done
  echo -e "${class}"
}

loadClass() {
  resolveClassFile() {
    local testPath=
    for path in "${GLOBAL_TranspilerPaths[@]}"; do
      testPath="${path}/${1}.class.sh"
      if [[ ! -e "${testPath}" ]]; then
        continue
      fi

      setVariable "${2}" "${testPath}"
      return
    done

    _logError "Classpath:"
    for path in "${GLOBAL_TranspilerPaths[@]}"; do
      _logError " - ${path}"
    done
    throwError "Unable to locate file for Class '${className}'" $? 2
  }

  local className=${1}
  local pathToClassFile=

  resolveClassFile "${className}" pathToClassFile

  local class=
  local parents=()
  local members=
  local staticMembers=
  local methods=
  local defaultValues=

  local fqn=Class_${className}
  [[ $(isFunction "${fqn}.class") ]] && return

  _logDebug "Loading class from file: ${className} from: ${pathToClassFile}"
  local rawClass="$(cat ${pathToClassFile})"
  class="${rawClass}"
  # shellcheck disable=SC2076
  [[ ! "${class}" =~ "${className}()" ]] && throwError "Could not find constructor matching class name '${className}' in class file: ${pathToClassFile}" 3

  parents=($(transpile_GetParentsClasses "${class}"))
  class="$(transpile_AppendParentClasses "${class}")"
  echo -e "${class}" > "${GLOBAL_TranspilerOutputTemplate}/${className}.class.sh"

  class="$(echo -e "${class}" | sed -E "s/_this/${className}___this/g")"
  class="$(echo -e "${class}" | sed -E "s/(${className}\(\) \{)/\1\\\n    declare __this\\\n    declare __class/g")"

  members=($(transpile_GetMemberNames "${class}"))
  staticMembers=($(transpile_GetStaticMemberNames "${class}"))
  methods=($(transpile_GetMethodsNames "${class}"))
  defaultValues=$(transpile_GetMembersDefaultValues "${className}" "${class}")

  class="$(transpile_Class "${className}" "${class}")"

  if [[ "${fqn}" == "Class_ClassObj" ]]; then
    # This is creating a new Class instance of the Class object
    class="$(echo -e "${class}" | sed -E "s/ClassObj/${fqn}/g")"

    saveAndSource "${class}" "${GLOBAL_TranspilerOutputClasses}/${className}.class.sh"
  else
    # This is creating a new Class instance of a new type
    new ClassObj "${className}"
  fi

  #  _logWarning "parent: ${parents[*]}"
  "${fqn}"
  local rawClassStart=$(echo -e "${rawClass}" | grep -n "${className}\(\)" | head -n 1 | cut -d: -f1)
  local rawClassEnd=$(echo -e "${rawClass}" | grep -n "}" | tail -n 1 | cut -d: -f1)
  rawClass=$(echo -e "${rawClass}" | sed -n "$((rawClassStart + 2)),$((rawClassEnd - 1))p")
  #  breakpoint "rawClass after"
  "${fqn}.rawClass" = "${rawClass}"
  "${fqn}.class" = "${class}"
  "${fqn}.defaultValues" = "${defaultValues}"
  "${fqn}.members" = "${members[*]}"
  "${fqn}.parents" = "${parents[*]}"
  "${fqn}.staticMembers" = "${staticMembers[*]}"
  "${fqn}.methods" = "${methods[*]}"
}

transpile_Class() {
  transpile_AllMembers() {
    transpile_ArrayMember() {
      local className=${1}
      local memberName=${2}
      local defaultValue=${3}

      local method="${OOS_TranspileConst_ArrayMemberWithGetterAndSetter}"
      method=$(echo "${method}" | sed -E "s/${OOS_TranspileConst_ClassName}/${className}/g")
      method=$(echo "${method}" | sed -E "s/${OOS_TranspileConst_Name}/${memberName}/g")

      echo "${method//$'\n'/'\\n'}"
    }

    transpile_Member() {
      local className=${1}
      local memberName=${2}
      local defaultValue=${3}

      local member="${OOS_TranspileConst_PrimitiveMemberWithGetterAndSetter}"
      member=$(echo -e "${member}" | sed -E "s/${OOS_TranspileConst_ClassName}/${className}/g")
      member=$(echo -e "${member}" | sed -E "s/${OOS_TranspileConst_Name}/${memberName}/g")

      member="${member//$'\n'/'\\n'}"
      echo "${member}"
    }

    local className=${1}
    local class="${2}"

    local members=($(transpile_GetMemberNames "${class}"))
    local members+=($(transpile_GetStaticMemberNames "${class}"))

    class=$(echo -e "${class}" | sed -E "s/declare ([a-zA-Z_]{1,})=.*$/declare \1/g")

    for member in "${members[@]}"; do
      class=$(echo -e "${class}" | sed -E "s/\\$\{#${member}/\${#${className}_${member}/g")
      class=$(echo -e "${class}" | sed -E "s/\\$\{${member}([\[\}:])/\${${className}_${member}\1/g")
      class=$(echo -e "${class}" | sed -E "s/${member}(\+|\[.*])?=/${className}_${member}\1=/g")
      class=$(echo -e "${class}" | sed -E "s/this\.${member}/${className}.${member}/g")
      class=$(echo -e "${class}" | sed -E "s/this_${member}/${className}_${member}/g")
      #      _logWarning "transpiling member: ${member}"
      if [[ "$(echo -e "${class}" | grep -E "declare -a ${member}")" ]]; then
        #        _logWarning "transpiling array member: ${member}"
        class=$(echo -e "${class}" | sed -E "s/declare -a ${member}$/$(transpile_ArrayMember "${className}" "${member}")/g")
      fi
      if [[ "$(echo -e "${class}" | grep -E "declare ${member}")" ]]; then
        class=$(echo -e "${class}" | sed -E "s/declare ${member}$/$(transpile_Member "${className}" "${member}")/g")
      fi

    done
    echo -e "${class}"
  }

  transpile_AllMethods() {
    local className=${1}
    local class="${2}"

    local methods=($(transpile_GetMethodsNames "${class}"))

    for method in "${methods[@]}"; do
      class=$(echo -e "${class}" | sed -E "s/_${method}\(\)/${className}.${method}()/g")
      class=$(echo -e "${class}" | sed -E "s/this.${method}/${className}.${method}/g")
    done
    echo -e "${class}"
  }

  local className=${1}
  local class="${2}"

  class=$(transpile_AllMembers "${className}" "${class}")
  class=$(transpile_AllMethods "${className}" "${class}")

  echo -e "${class}"
}

transpile_GetMembersDefaultValues() {
  echo -e "${2}" | grep -E "declare.*=.+$" | sed -E "s/declare ([a-zA-Z_]{1,})=(.*)$/${1}.\1 = \2/g"
}

transpile_GetMemberNames() {
  echo -e "${1}" | grep -E "declare [-a-zA-Z].*" | sed -E "s/.*declare (-a )?([a-zA-Z][a-zA-Z_]{1,}).*$/\2/g"
}

transpile_GetParentsClasses() {
  echo -e "${1}" | grep -E "extends class [a-zA-Z].*" | sed -E "s/.*extends class ([a-zA-Z][a-zA-Z_]{1,}).*$/\1/g"
}

transpile_GetStaticMemberNames() {
  echo -e "${1}" | grep -E "declare __.*" | sed -E "s/.*declare (array )?(__[a-zA-Z_]{1,}).*$/\2/g"
}

transpile_GetMethodsNames() {
  echo -e "${1}" | grep -E ".*_.*() ?\{$" | sed -E "s/ *_([a-zA-Z][a-zA-Z_\.]{1,})\(\) ?\{$/\1/g"
}
