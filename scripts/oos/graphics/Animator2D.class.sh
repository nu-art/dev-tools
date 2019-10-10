#!/bin/bash

Animator2D() {

    declare startFrame
    declare endFrame
    declare drawable
    declare interpolatorX
    declare interpolatorY

    _calculateX() {
        setVariable ${1} `eval "echo \"${interpolatorX}\"" | bc`;
    }

    _calculateY() {
        setVariable ${1} `eval "echo \"${interpolatorY}\"" | bc`;
    }
}

