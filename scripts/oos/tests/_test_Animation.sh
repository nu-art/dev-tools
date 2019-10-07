#!/bin/bash

source ../core/transpiler.sh
addTranspilerPath `pwd`/../graphics

function _cloud2() {
    echo -e "    .--
   (   )
  (   .  )
(   (   ))
\`- __.'"
}

function _cloud1() {
  echo -e "   _
 (\`  ).
(      ).
(     (   '\`.
 (   )     .  )
  (..__.:'--''"

}


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

run

#echo abcdefghijklmnopqrstvuwxyz | sed "s/./Asd/5"

#
