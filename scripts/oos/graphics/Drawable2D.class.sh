#!/bin/bash

Drawable2D() {

    declare delimiter=K
    declare animObj
    declare x
    declare y
    declare width
    declare height
    declare array lines
    declare array offsets

    _init() {
        local temp=(`echo -e "${animObj}" | sed -E "s/ /${delimiter}/g" | sed -E "s/(.*)$/\1/g"`)
        local linesTemp=()
        local offsetTemp=()

        height=${#temp[@]}
        for (( i=0; i<=${#temp[@]}; i+=1 )); do
            offsetTemp[${i}]="$(echo "${temp[${i}]}" | sed -E "s/(^${delimiter}*).*/\1/")"
            offsetTemp[${i}]=${#offsetTemp[${i}]}

            linesTemp[${i}]="$(echo "${temp[${i}]}" | sed -E "s/^${delimiter}*(.*)$/\1/" | sed -E "s/${delimiter}/ /g")"
        done

        lines=("${linesTemp[@]}")
        offsets=("${offsetTemp[@]}")
#        for (( i=0; i<=${height}; i+=1 )); do
#            echo ${offset[$i]}
#        done
#        for (( i=0; i<=`cloud.height`; i+=1 )); do
##            echo ${lines[$i]}
#        done

    }

    _getLine(){
        echo "${lines[${1}]}"
    }
    _getOffset(){
        echo "${offsets[${1}]}"
    }
}

