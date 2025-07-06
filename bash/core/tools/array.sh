#!/bin/bash

## @function: array.contains(item, ...list)
##
## @description: Check if an item is in a list
##
## @return: true if contained, null otherwise
array.contains() {
  for i in "${@:2}"; do
    if [[ "$i" == "$1" ]]; then
      echo "true"
      return
    fi
  done
}

## @function: array.remove(arrayVarName, ...itemToRemoves)
##
## @description: remove the given list of items from the array
##
## @return: void
array.remove() {
  local arrayVarName=${1}
  local itemToRemoves=("${@:2}")
  for itemToRemove in "${itemToRemoves[@]}"; do
    for i in $(eval "echo \${!${arrayVarName}[@]}"); do
      local ref="${arrayVarName}[${i}]"
      if [[ "${!ref}" == "${itemToRemove}" ]]; then
        unset "${ref}"
      fi
    done
  done
}

## @function: array.isArray(arrayVarName)
##
## @description: Check if a variable is an array
##
## @return: true if it's an array, nothing otherwise
array.isArray() {
  local arrayVarName="$1"
  if [[ "$(declare -p "$arrayVarName" 2>/dev/null)" =~ "declare -a" ]]; then
    echo true
  fi
}

## @function: array.setVariable(arrayVarName, ...values)
##
## @description: Assign values into a named array
##
## @return: void
array.setVariable() {
  local arrayVarName="$1"
  local values="${*:2}"
  eval "$arrayVarName=(\$values)"
}

## @function: array.filterDuplicates(arrayVarName)
##
## @description: Filters duplicated items in the array
##
## @return: modifies the array in-place to contain only unique items
array.filterDuplicates() {
  local arrayName="$1"
  local temp=()
  for item in $(eval "echo \${${arrayName}[@]}"); do
    [[ $(array.contains "$item" "${temp[@]}") ]] && continue
    temp+=("$item")
  done
  array.setVariable "$arrayName" "${temp[@]}"
}

## @function: array.map(fromArrayVarName, toArrayVarName, mapperFn)
##
## @description: Maps each item using a mapper function and stores result in new array
##
## @return: void
array.map() {
  local fromArray="$1"
  local toArray="$2"
  local mapper="$3"

  local temp=()
  for item in $(eval "echo \${${fromArray}[@]}"); do
    temp+=("$(${mapper} "$item")")
  done

  array.setVariable "$toArray" "${temp[@]}"
}

## @function: array.forEach(arrayVarName, consumerFn)
##
## @description: Runs a consumer function on each item in the array
##
## @return: void
array.forEach() {
  local arrayName="$1"
  local mapper="$2"

  for item in $(eval "echo \${${arrayName}[@]}"); do
    "$mapper" "$item"
  done
}
