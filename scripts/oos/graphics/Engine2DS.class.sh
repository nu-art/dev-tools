#!/bin/bash

Engine2DS() {

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

            local progress=`echo " (${frame} - ${startFrame}) / (${endFrame} - ${startFrame}) " | bc -l`
#            >&2 echo "HERE" ${animator}

            local x=
            local y=
            ${animator}.calculateX x ${progress} ${width} ${height}
            ${animator}.calculateY y ${progress} ${width} ${height}
            local drawable=`${animator}.drawable`
            canvas.paint ${drawable} ${x} ${y}
        done
        canvas.draw
        canvas.clean
    }
}

