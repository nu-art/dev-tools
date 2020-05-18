#!/bin/bash

Class_ClassObj() {

    local Class_ClassObj___this=
    Class_ClassObj.__this() {
        if [[ "$1" == "=" ]]; then
            Class_ClassObj___this="$2"
        else
            echo "${Class_ClassObj___this}"
        fi
    }


    local Class_ClassObj___class=
    Class_ClassObj.__class() {
        if [[ "$1" == "=" ]]; then
            Class_ClassObj___class="$2"
        else
            echo "${Class_ClassObj___class}"
        fi
    }



    local Class_ClassObj_parents=
    Class_ClassObj.parents() {
        if [[ "$1" == "=" ]]; then
            Class_ClassObj_parents="$2"
        else
            echo "${Class_ClassObj_parents}"
        fi
    }


    local Class_ClassObj_rawClass=
    Class_ClassObj.rawClass() {
        if [[ "$1" == "=" ]]; then
            Class_ClassObj_rawClass="$2"
        else
            echo "${Class_ClassObj_rawClass}"
        fi
    }


    local Class_ClassObj_members=
    Class_ClassObj.members() {
        if [[ "$1" == "=" ]]; then
            Class_ClassObj_members="$2"
        else
            echo "${Class_ClassObj_members}"
        fi
    }


    local Class_ClassObj_staticMembers=
    Class_ClassObj.staticMembers() {
        if [[ "$1" == "=" ]]; then
            Class_ClassObj_staticMembers="$2"
        else
            echo "${Class_ClassObj_staticMembers}"
        fi
    }


    local Class_ClassObj_methods=
    Class_ClassObj.methods() {
        if [[ "$1" == "=" ]]; then
            Class_ClassObj_methods="$2"
        else
            echo "${Class_ClassObj_methods}"
        fi
    }


    local Class_ClassObj_defaultValues=
    Class_ClassObj.defaultValues() {
        if [[ "$1" == "=" ]]; then
            Class_ClassObj_defaultValues="$2"
        else
            echo "${Class_ClassObj_defaultValues}"
        fi
    }

}
