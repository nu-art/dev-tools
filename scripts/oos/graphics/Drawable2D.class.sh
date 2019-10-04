#!/bin/bash

Drawable2D() {

    declare animObj
    declare x
    declare y
    declare width
    declare height

    _animate() {
        x=${1}
        y=${2}

        local replacer=`seq  -f " " -s '' ${1}`
        local temp=`echo "${animObj}" | sed -E "s/OS/${replacer}/"`
        echo -e "${temp}"
    }
}

