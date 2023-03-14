#!/bin/bash

DIR1=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${DIR1}/../../core/transpiler.sh"
source "${DIR1}/clouds.sh"

CONST_Debug=true
addTranspilerClassPath "${DIR1}/../../graphics"

run() {
  new Canvas2D canvas
  new Drawable2D cloud1
  new Drawable2D cloud2

  canvas.width = 100
  canvas.height = 10
  canvas.prepare
  #canvas.clean
  #
  cloud1.animObj = "$(_cloud2)"
  cloud1.init

  cloud2.animObj = "$(_cloud1)"
  cloud2.init

  fromX=10
  toX=80
  dx=1

  for ((x = fromX; x != toX; x += dx)); do
    canvas.prepare
    canvas.paint cloud1 ${x} 1
    canvas.paint cloud1 $((${x} + 5)) 1
    canvas.paint cloud2 $((90 - ${x})) 3
    canvas.draw
    canvas.clean
  done
  canvas.draw
}

runEngine() {
  createEngine() {
    new Engine2D engine
    new Canvas2D canvas
    canvas.width = 100
    canvas.height = 20
    engine.canvas = canvas
  }

  createCloud() {
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

    anim_${name}.interpolatorX = "${calcX}"
    anim_${name}.interpolatorY = "${calcY}"
    engine.addAnimation anim_${name}
  }

  createEngine

  createCloud cloud1 "$(_cloud1)" 5 90 "(\${2} * 80)/1" "(2 + \${2} * 6)/1"
  createCloud cloud3 "$(_cloud3)" 5 90 "(\${2} * 80)/1" "(10 - (2 + \${2} * 6))/1"
  createCloud cloud2 "$(_cloud2)" 5 90 "(80 - \${2} * 80)/1" "(2 + \${2} * 6)/1"
  createCloud cloud4 "$(_cloud4)" 5 90 "(80 - \${2} * 80)/1" "(10 - (2 + \${2} * 6))/1"

  engine.frame = 0
  engine.totalFrames = 100
  time engine.start
}

runEngine
