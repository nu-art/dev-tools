#!/bin/bash

Animator2D() {

    declare startFrame
    declare endFrame
    declare drawable
    declare interpolatorX
    declare interpolatorY

    _calculateX() {
        ${interpolatorX} ${1} ${2} ${3} ${4}
    }

    _calculateY() {
        ${interpolatorY} ${1} ${2} ${3} ${4}
    }
}

