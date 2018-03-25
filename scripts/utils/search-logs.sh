#!/bin/bash
folder=${1}
echo "Searching for crashes in folder: ${folder}"

pushd "${folder}"
pwd
    mv logs00.txt logs-00.txt

    for file in logs*.zip; do
        [ -e "$file" ] || continue
        # ... rest of the loop body

        index=`echo ${file} | sed -E "s/logs(..).zip/\1/"`
        unzip ${file} -d temp-${index} > NUL
        mv temp-${index}/logs00.txt logs-${index}.txt
        rm ${file}
        rm -rf temp-${index}
    done


    mv logcat.txt logcat.txt.00
    for file in logcat.txt*; do
        [ -e "$file" ] || continue
        # ... rest of the loop body

        outputName=`echo ${file} | sed -E "s/logcat\.txt\.(..)/logcat-\1.txt/"`
        echo ${outputName}
        mv ${file} ${outputName}
    done

    echo "Application started:"
    grep -rnw '.' --include=\*.txt -e 'Application started'
    echo

    echo "On boot completed"
    grep -rnw '.' --include=\*.txt -e 'Boot completed'
    echo

    echo "Process Killed by system:"
    grep -rnw '.' --include=\*.txt -e 'Process com.ir.ai.kyou'
    echo

    echo "Process crashed:"
    grep -rnw '.' --include=\*.txt -e 'Crash on thread'
    grep -rnw '.' --include=\*.txt -e 'FATAL'
    echo

    echo "Process died:"
    grep -rnw '.' --include=\*.txt -e 'SIG'
    echo
    echo
    echo


    echo "Searching for exceptions:"
    grep -rnw '.' --include=\*.txt -e 'Exception'
    echo

popd
