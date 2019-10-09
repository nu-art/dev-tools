#!/bin/bash

Animator2D() {

    declare startFrame
    declare endFrame
    declare drawable
    declare interpolatorX
    declare interpolatorY

    _calculateX() {
        local name=${1}
        local progress=${2}
        local width=${3}
        local height=${4}

        ${interpolatorX} ${name} ${progress} ${width} ${height}
    }

    _calculateY() {
        local name=${1}
        local progress=${1}
        local width=${2}
        local height=${3}

        ${interpolatorY} ${name} ${progress} ${width} ${height}
    }
}

