#!/bin/bash

source ../core/transpiler.sh
addTranspilerPath ${BASH_SOURCE%/*}/../graphics

function _cloud2() {
    echo -e "OS    .--
OS   (   )
OS  (   .  )
OS(   (   ))
OS\`- __.'  "
}

new Canvas2D canvas
new Drawable2D cloud

canvas.width = 100
canvas.height = 8
canvas._clean

cloud.animObj = "`_cloud2`"