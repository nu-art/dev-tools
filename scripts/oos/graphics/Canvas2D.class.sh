#!/bin/bash

Canvas2D() {

    declare buffer
    declare width
    declare height

    _clean() {
        buffer=`seq -f "-" -s '' $((${width} * ${height}))`
        for ((i=0; i< ${height}; i++)); do
            tput cuu1
        done
    }

    _paint() {
        local animation=${1}
        local x=${2}
        local y=${3}

        buffer=`seq  -f " " -s '' ${1}`

        local temp=`echo "${animObj}" | sed -E "s/OS/${replacer}/"`
        echo -e "${temp}"
    }

    _draw() {
        echo -e `echo -e "${buffer}" | sed -E "s/.{${width}}/\1\n/g"`
    }
}

