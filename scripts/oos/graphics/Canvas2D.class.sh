#!/bin/bash

Canvas2D() {

    declare buffer
    declare width
    declare height

    _prepare() {
        buffer=()
    }

    _paint() {
        local animation=${1}
        local x=${2}
        local y=${3}
        local animHeight=`${animation}.height`
        for (( i=0; i<${animHeight}; i+=1 )); do
            local line=`${animation}.getLine ${i}`
            local offset=`${animation}.getOffset ${i}`

            lineAsArray=()
            for (( l=0 ; l < ${#line} ; l++ )); do lineAsArray[l]=${line:l:1}; done

            local position1=$(( (${i} + ${y}) * ${width} + ${x} + ${offset} ))
            local position2=$(( ${position1} + ${#line} ))
#            >&2 logDebug "${animation} (${x},${y}) ${line}"

            for (( k=0; k<${#lineAsArray[@]}; k+=1)); do
                local index=$((${position1} + ${k}))

#                >&2 logDebug "${animation} (${x},${y}) ${index} ${lineAsArray[${k}]}"
                buffer[${index}]="${lineAsArray[${k}]}"
            done
#            buffer="${buffer:0:${position1}}${line}${buffer:${position2}}"
        done
    }

    _clean() {
        for ((i=0; i< ${height}; i++)); do
            tput cuu1 tput el
        done
    }

    _draw() {
        local char
        for (( h=0; h<${height}; h+=1 )); do
            local limit=$(( (h+1) * ${width} ))
            echo -n A
            for (( w=$(( h * ${width} )); w<limit; w+=1 )); do
                char=${buffer[${w}]-" "}
                echo -n "${char}"
            done
            echo B
        done
    }
}

