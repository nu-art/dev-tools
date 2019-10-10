#!/bin/bash

Canvas2DS() {

    declare buffer
    declare width
    declare height

    _prepare() {
        buffer=`seq -f " " -s '' $((${width} * ${height}))`
    }

    _paint() {
        local animation=${1}
        local x=${2}
        local y=${3}
        local animHeight=`${animation}.height`
        for (( i=0; i<${animHeight}; i+=1 )); do
            local line=`${animation}.getLine ${i}`
            local offset=`${animation}.getOffset ${i}`

            local position1=$(( (${i} + ${y}) * ${width} + ${x} + ${offset} ))
            local position2=$(( ${position1} + ${#line} ))

            buffer="${buffer:0:${position1}}${line}${buffer:${position2}}"
        done
    }

    _clean() {
        for ((i=0; i< ${height}; i++)); do
            tput cuu1 tput el
        done
    }

    _draw() {
        for (( h=0; h<${height}; h+=1 )); do
            echo "A${buffer:$(( ${h} * ${width} )):${width}}B"
        done
    }
}

