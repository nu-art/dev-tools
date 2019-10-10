#!/bin/bash

Engine2D() {

    declare canvasCount=0
    declare array canvas=()
    declare width
    declare height
    declare array animators
    declare totalFrames=1
    declare frame=0

    _addAnimation() {
        animators=("${animators[@]}" "${1}")
    }

    _start() {
        eval "new Canvas2D canvas1"
        while (( ${frame} < ${totalFrames} )); do
            this.render
#            sleep 0.05
            frame=$(( ${frame} + 1 ))
        done
    }


    _render() {
        canvas1.width = ${width}
        canvas1.height = ${height}

        pickedCanvas=canvas1
        ${pickedCanvas}.prepare
        local width=${pickedCanvas}.width
        local height=${pickedCanvas}.height

        for animator in "${animators[@]}"; do
            local startFrame=`${animator}.startFrame`
            local endFrame=`${animator}.endFrame`
            if (( ${frame} < ${startFrame} ));then
                continue
            fi

            if (( ${frame} >= ${endFrame} ));then
                continue
            fi

#            local progress="0.5"
            local progress=`echo " (${frame} - ${startFrame}) / (${endFrame} - ${startFrame}) " | bc -l`

#            local posX=`${animator}.calculateX posX ${progress} ${width} ${height}`
#            local posY=`${animator}.calculateY posY ${progress} ${width} ${height}`

            local posX=
            ${animator}.calculateX posX ${progress} ${width} ${height}
            local posY=
            ${animator}.calculateY posY ${progress} ${width} ${height}

#            >&2 echo "Render: ${animator} (${posX}, ${posY})"
            local drawable=`${animator}.drawable`
            ${pickedCanvas}.paint ${drawable} ${posX} ${posY}

#            pickedCanvas.paint ${drawable} 80 4
        done
        ${pickedCanvas}.draw
        ${pickedCanvas}.clean
#        sleep 0.01
    }
}

