#!/bin/bash
# Run .rb files through ruby -c and json through mson.tool for linting

refname=$1
old=$2
new=$3

function validateJSON {
 for file in $(git diff --name-status $old $new | grep -P '^([AM]).*((js)|(json))$' | sed 's/^..//'); do
    git cat-file blob $new:$file | python2.6 -mjson.tool &> /dev/null
    if [ $? -ne 0 ] ; then
        output=$(git cat-file blob $new:$file | python2.6 -mjson.tool 2>&1)
        echo $file
    fi
 done
}

function validateRUBY {
 for file in $(git diff --name-status $old $new | grep -P '^([AM]).*(\.rb)$' | sed 's/^..//') ; do
    git cat-file blob $new:$file | ruby -c &>/dev/null
    if [ $? -ne 0 ] ; then
        git cat-file blob $new:$file | ruby -c 1>/dev/null
        echo $file
    fi
 done
}

validateJSON
if [ $? -ne 0 ] ; then
    echo $?
    exit 1
fi

validateRUBY
if [ $? -ne 0 ] ; then
    echo $?
    exit 1
fi
