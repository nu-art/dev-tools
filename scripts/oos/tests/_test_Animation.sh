#!/bin/bash

source ../core/transpiler.sh
source ./clouds/clouds.sh

addTranspilerPath `pwd`/../graphics

function run() {
    new Canvas2D canvas
    new Drawable2D cloud1
    new Drawable2D cloud2

    canvas.width = 100
    canvas.height = 10
    canvas.prepare
    #canvas.clean
    #
    cloud1.animObj = "`_cloud2`"
    cloud1.init

    cloud2.animObj = "`_cloud1`"
    cloud2.init

    fromX=10
    toX=80
    dx=1

    for (( x=${fromX}; x != ${toX}; x+=${dx} )); do
        canvas.prepare
        canvas.paint cloud1 ${x} 1
        canvas.paint cloud1 $((${x} + 5)) 1
        canvas.paint cloud2 $(( 90 - ${x})) 3
        canvas.draw
        canvas.clean
        sleep 0.01
    done
    canvas.draw
}

function runEngine() {
    function createEngine() {
        new Engine2DS engine
        new Canvas2DS canvas
        canvas.width = 100
        canvas.height = 15
        engine.canvas = canvas
    }

    function createCloud() {
        local name=${1}
        local image=${2}
        local startFrame=${3}
        local endFrame=${4}
        local calcX=${5}
        local calcY=${6}

        new Drawable2D ${name}
        new Animator2D anim_${name}

        ${name}.animObj = "${image}"
        ${name}.init

        anim_${name}.drawable = ${name}
        anim_${name}.startFrame = 5
        anim_${name}.endFrame = 90

#        eval "${name}_calcX() { echo \"${calcX}\" | bc; }"
#        eval "${name}_calcY() { echo \"${calcY}\" | bc; }"
        eval "${name}_calcX() { setVariable \${1} \`echo \"${calcX}\" | bc;\`; }"
        eval "${name}_calcY() { setVariable \${1} \`echo \"${calcY}\" | bc;\`; }"
#        eval "${name}_calcX() { echo \"${calcX}\" | bc; }"
#        eval "${name}_calcY() { echo \"${calcY}\" | bc; }"

#        eval "${name}_calcX() { setVariable \${1} \"80\"; }"
#        eval "${name}_calcY() { setVariable \${1} \"2\"; }"

        anim_${name}.interpolatorX = ${name}_calcX
        anim_${name}.interpolatorY = ${name}_calcY
        engine.addAnimation anim_${name}
    }
    createEngine
#    createCloud cloud1 "`_cloud1`" 5 90 "80" "4"
#    createCloud cloud3 "`_cloud3`" 5 90 "80" "4"
#    createCloud cloud2 "`_cloud2`" 5 90 "80" "4"
#    createCloud cloud4 "`_cloud4`" 5 90 "80" "4"

    createCloud cloud1 "`_cloud1`" 5 90 "(\${2} * 80)/1" "(2 + \${2} * 6)/1"
    createCloud cloud3 "`_cloud3`" 5 90 "(\${2} * 80)/1" "(10 - (2 + \${2} * 6))/1"
    createCloud cloud2 "`_cloud2`" 5 90 "(80 - \${2} * 80)/1" "(2 + \${2} * 6)/1"
    createCloud cloud4 "`_cloud4`" 5 90 "(80 - \${2} * 80)/1" "(10 - (2 + \${2} * 6))/1"



    engine.frame = 0
    engine.totalFrames = 100
    time engine.start
}
runEngine
#run

#foo="01 2345  6789"
#bar=($(echo $foo|sed  's/\(.\)/\1 /g'))

#echo ${#bar[@]}
#buffer=()
#buffer[0]=A
#buffer[100]=Z
#buffer[300]=k
#
#echo "${buffer[*]}"
#echo "${#buffer[@]}"
#echo "${buffer[0]}"
#echo "${buffer[2]}"
#echo "${buffer[300]}"
#echo abcdefghijklmnopqrstvuwxyz | sed "s/./Asd/5"