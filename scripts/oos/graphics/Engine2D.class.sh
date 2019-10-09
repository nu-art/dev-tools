#!/bin/bash

Engine2D() {

    declare canvas
    declare array animators
    declare totalFrames=1
    declare frame=0

    _addAnimation() {
        animators=("${animators[@]}" "${1}")
    }

    _start() {
        while (( ${frame} < ${totalFrames} )); do
            this.render
            frame=$(( ${frame} + 1 ))
        done

        canvas.draw
    }

    _render() {
        canvas.prepare
        local width=canvas.width
        local height=canvas.height

        for animator in "${animators[@]}"; do
            local startFrame=`${animator}.startFrame`
            local endFrame=`${animator}.endFrame`
            if (( ${frame} < ${startFrame} ));then
                continue
            fi

            if (( ${frame} >= ${endFrame} ));then
                continue
            fi

            local progress="0.5"
            local progress=`echo " (${frame} - ${startFrame}) / (${endFrame} - ${startFrame}) " | bc -l`

            local posX=
            ${animator}.calculateX posX ${progress} ${width} ${height}
            local posY=
            ${animator}.calculateY posY ${progress} ${width} ${height}

#            >&2 echo "Render: ${animator} (${posX}, ${posY})"
            local drawable=`${animator}.drawable`
            canvas.paint ${drawable} ${posX} ${posY}

#            canvas.paint ${drawable} 80 4
        done
        canvas.draw
        canvas.clean
#        sleep 0.01
    }
}

