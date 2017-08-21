#!/bin/sh
# (c) Copyright 2017 Capsule 8, Inc (capsule8.io)
#
# test_coverage gets coverage metrics for specific or all packages.
# You can pass 'summary' to just get coverage percentage 
# or you can pass report to bring up a graphic report in 
# your default web browser.

set -o errexit
set -o nounset
set -o pipefail

export CGO_ENABLED=0

UNIT_TEST_PKG_FILE="./unit_tests.txt"
UNIT_TEST_PREFIX="github.com/capsule8/capsulator-template"
PROJ_ROOT=`pwd`
RET=0

PKGS_TO_TEST=$(for d in "$@"; do echo ./$d/...; done)

setupFakeGoWorkspace() {
    CUR_DIR=$(pwd)
    export GOPATH=$(mktemp -d)
    cd $GOPATH
    /bin/mkdir ./src
    /bin/mkdir ./pkg
    /bin/mkdir ./bin

    /bin/mkdir -p ./src/github.com/capsule8
    echo "Symlinking repo $CUR_DIR to $GOPATH/src/$UNIT_TEST_PREFIX"
    ln -s $CUR_DIR ./src/$UNIT_TEST_PREFIX
}

cleanUp() {
    echo "Cleaning up $GOPATH"
    rm -rf $GOPATH
}

genSummary() {
    if [[ $1 == "" ]]; 
    then
        cd $GOPATH/src/$UNIT_TEST_PREFIX
        for package in $PKGS_TO_TEST; do
        if [[ $package != "#*" ]]; then
            go test -coverprofile=coverage.out "$UNIT_TEST_PREFIX/$package" | grep coverage
            if [ "$?" != "0" ]; then
                return 1
            fi
        fi
        done
        return 0
    
    else 
        go test -coverprofile=coverage.out $UNIT_TEST_PREFIX/$1 | grep coverage
        if [ "$?" != "0" ]; then
            return 1
        fi
    fi
}

genReport() {
    if [[ $1 == "" ]]; 
    then
        cd ./src/$UNIT_TEST_PREFIX
        for package in $PKGS_TO_TEST; do
            REPORT_ROOT=$(pwd)
            if [[ $package != "#*" ]]; then
                cd $package
                go test -coverprofile=coverage.out 
                go tool cover -html=coverage.out
                rm coverage.out
                if [ "$?" != "0" ]; then
                    return 1
                fi
                cd $REPORT_ROOT
            fi
        done
        return 0

    else
        cd ./src/$UNIT_TEST_PREFIX/$1 
        go test -coverprofile=coverage.out 
        go tool cover -html=coverage.out
        if [[ "$?" != "0" ]];
        then
           return 1
        else
           return 0
        fi
        rm coverage.out
    fi
}

if [[ $1 == "report" ]]; then
    setupFakeGoWorkspace
    genReport $2
    RET=$?
    cleanUp
    rm -f coverage.out
    exit $RET
fi

if [[ $1 == "summary" ]]; then
    setupFakeGoWorkspace
    genSummary $2 
    RET=$?
    cleanUp
    rm -f coverage.out
    exit $RET
fi

if [[ $1 == "packages" ]]; then 
    for package in $PKGS_TO_TEST; do
        echo $package 
    done
    exit 0
fi

echo "Use 'report', 'summary', or 'packages'. For report and summary, you can specify specific packages (relative path)"