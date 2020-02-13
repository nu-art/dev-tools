#!/bin/bash

function printHelp() {
    local pc="${BBlue}"
    local group="${BCyan}"
    local param="${BPurple}"
    local err="${BRed}"
    local dc="${Green}"
    local dcb="${BGreen}"
    local noColor="${NoColor}"

    logVerbose " ==== ${group}General:${noColor} ===="
    logVerbose
    logVerbose "   ${pc}--help | -h${noColor}"
    logVerbose "        ${dc}This Menu${noColor}"
    logVerbose
    logVerbose "   ${pc}--print-env${noColor}"
    logVerbose "        ${dc}Will print the current versions of the important tools${noColor}"
    logVerbose
    logVerbose "   ${pc}--use-thunderstorm-sources${noColor}"
    logVerbose "        ${dc}Will print the current versions of the important tools${noColor}"
    logVerbose
    logVerbose

    logVerbose " ==== ${group}CLEAN:${noColor} ===="
    logVerbose
    logVerbose "   ${pc}--purge${noColor}"
    logVerbose "        ${dc}Will delete the node_modules folder in all modules${noColor}"
    logVerbose "        ${dc}Will perform --clean{noColor}"
    logVerbose
    logVerbose "   ${pc}--clean${noColor}"
    logVerbose "        ${dc}Will delete the dist folder in all modules${noColor}"
    logVerbose
    logVerbose

    logVerbose " ==== ${group}BUILD:${noColor} ===="
    logVerbose
    logVerbose "   ${pc}--setup${noColor}"
    logVerbose "        ${dc}Will link all modules and create link dependencies${noColor}"
    logVerbose
    logVerbose "   ${pc}--unlink${noColor}"
    logVerbose "        ${dc}Will purge & setup without dependencies${noColor}"
    logVerbose
    logVerbose "   ${pc}--link | -l${noColor}"
    logVerbose "        ${dc}Would link dependencies between projects${noColor}"
    logVerbose
    logVerbose "   ${pc}--link-only | -lo${noColor}"
    logVerbose "        ${dc}Would ONLY link dependencies between projects${noColor}"
    logVerbose
    logVerbose "   ${pc}--no-build | -nb${noColor}"
    logVerbose "        ${dc}Skip the build${noColor}"
    logVerbose
    logVerbose "   ${pc}--no-thunderstorm | -nts${noColor}"
    logVerbose "        ${dc}Completely ignore Thunderstorm infra${noColor}"
    logVerbose
    logVerbose "   ${pc}--lint${noColor}"
    logVerbose "        ${dc}Run lint on all the packages${noColor}"
    logVerbose
    logVerbose "   ${pc}--rebuild-on-change | -roc${noColor}"
    logVerbose "        ${dc}listen and rebuild on changes in modules${noColor}"
    logVerbose
    logVerbose "   ${pc}--thunderstorm-home=<${param}path-to-thunderstorm${pc}> | -th=<${param}path-to-thunderstorm${pc}>${noColor}"
    logVerbose "        ${dc}Will link the output folder of the libraries of thunderstorm that exists under the give path${noColor}"
    logVerbose
    logVerbose

    logVerbose " ==== ${group}TEST:${noColor} ===="
    logVerbose
    logVerbose "   ${pc}--test-modules | -tm${noColor}"
    logVerbose "        ${dc}Run tests in all modules${noColor}"
    logVerbose
    logVerbose "   ${pc}--launch-backend-test-mode | -lbtm${noColor}"
    logVerbose "        ${dc}Setting project env to test and running the backend locally${noColor}"
    logVerbose
    logVerbose "   ${pc}--run-backend-tests | -rbt{noColor}"
    logVerbose "        ${dc}Run the backend test${noColor}"
    logVerbose
    logVerbose

    logVerbose " ==== ${group}LAUNCH:${noColor} ===="
    logVerbose
    logVerbose "   ${pc}--launch${noColor}"
    logVerbose "        ${dc}Will launch both frontend & backend${noColor}"
    logVerbose
    logVerbose "   ${pc}--launch-frontend${noColor}"
    logVerbose "        ${dc}Will launch ONLY frontend${noColor}"
    logVerbose
    logVerbose "   ${pc}--launch-backend${noColor}"
    logVerbose "        ${dc}Will launch ONLY backend${noColor}"
    logVerbose
    logVerbose

    logVerbose " ==== ${group}DEPLOY:${noColor} ===="
    logVerbose
    logVerbose "   ${pc}--deploy${noColor}"
    logVerbose "        ${dc}Will deploy both frontend & backend${noColor}"
    logVerbose
    logVerbose "   ${pc}--deploy-frontend${noColor}"
    logVerbose "        ${dc}Will deploy ONLY frontend${noColor}"
    logVerbose
    logVerbose "   ${pc}--deploy-backend${noColor}"
    logVerbose "        ${dc}Will deploy ONLY backend${noColor}"
    logVerbose
    logVerbose "   ${pc}--set-env=<${param}envType${pc}> | -se=<${param}envType${pc}>${noColor}"
    logVerbose "        ${dc}Will set the .config-\${envType}.json as the current .config.json and prepare it as base 64 for local usage${noColor}"
    logVerbose
    logVerbose

    logVerbose " ==== ${group}PUBLISH:${noColor} ===="
    logVerbose
    logVerbose "   ${pc}--version-nu-art=< ${param}major${noColor} | ${param}minor${noColor} | ${param}patch${noColor} >${noColor}"
    logVerbose "        ${dc}Promote nu-art dependencies version${noColor}"
    logVerbose
    logVerbose "   ${pc}--version-app=< ${param}major${noColor} | ${param}minor${noColor} | ${param}patch${noColor} >${noColor}"
    logVerbose "        ${dc}Promote app dependencies version${noColor}"
    logVerbose
    logVerbose "   ${pc}--publish${noColor}"
    logVerbose "        ${dc}Publish artifacts to npm${noColor}"
    logVerbose

    logVerbose " ==== ${group}SUPER:${noColor} ===="
    logVerbose
    logVerbose "   ${pc}--merge-origin"
    logVerbose "        ${dc}Pull and merge from the forked repo${noColor}"
    logVerbose
    logVerbose "   ${pc}--use-thunderstorm-sources${noColor}"
    logVerbose "        ${dc}Add thunderstorm dependencies sources${noColor}"
    logVerbose

    exit 0
}
