#!/bin/bash
# Quick and dirty script to save time on rebuilding both the images. This is awful and should be scrapped ASAP in favour of pipelines.
#
BASEREPO="pabar19"

function help {
    echo "Helper to build the docker images"
    echo ""
    echo "Usage:"
    echo "$0 major|minor|patch [--only=x|-o x] [--local|-l] [--help|-h]"
    echo ""
    echo "Arguments:"
    echo "major|minor|patch     Accpeted values: only one of major|minor|patch"
    echo "                      Required"
    echo "                      Used to: identify the value to bump in the semver tag (major.minor.patch)"
    echo "--only=x|-o x         Accpeted values: --only=x or -o x  Replace x with a string of one of the images"
    echo "                      Optional"
    echo "                      Used to: specify only one of the images to build."
    echo "--local|-l            Accpeted values: --only=string or -o string"
    echo "                      Optional"
    echo "                      Used to: build only locally and not push to the registry"
    echo "--help|-h             Accpeted values: NA"
    echo "                      Optional"
    echo "                      Used to: print this help and exit"
    echo ""
    exit 0
}

while [[ $# -gt 0 ]] ;
do
    opt="$1";
    case "$opt" in
        "major" )
            MAJORCHANGE=true
            shift;;
        "minor" )     # alternate format: --first=date
            MINORCHANGE=true
            shift;;
        "patch" )
            PATCHCHANGE=true
            shift;;
        "--only="* )
            ONLY="${opt#*=}"
            shift;;
        "-o" )
            ONLY="$2"
            shift 2;;
        "--local"|"-l" )
            LOCAL=true
            shift;;
        "--help"|"-h")
            help
            shift;;
        *) echo >&2 "Invalid option: $@"; exit 1;;
   esac
done

if ! [ -z "$MAJORCHANGE" ]; then
    if ! [ -z "$MINORCHANGE" ] || ! [ -z "$PATCHCHANGE" ]; then
        echo "Only one is allowed"
    fi
elif ! [ -z "$MINORCHANGE" ]; then
    if ! [ -z "$MAJORCHANGE" ] || ! [ -z "$PATCHCHANGE" ]; then
        echo "Only one is allowed"
    fi
elif ! [ -z "$PATCHCHANGE" ]; then
    if ! [ -z "$MAJORCHANGE" ] || ! [ -z "$MINORCHANGE" ]; then
        echo "Only one is allowed"
    fi
else
    echo "Select one update entity"
fi

if [ -z "$ONLY" ]; then
    DIRS="$(find . -mindepth 1 -maxdepth 1 -type d)"
else
    DIRS="$(ls | grep $ONLY)"
fi
 for d in $(echo $DIRS | sort); do
    cd $d
    IMAGENAME=$(echo $d | cut -d '-' -f 2-)
    MAJORSTART="$(awk -F '.' '{ print $1 }' lastbuilt)"
    MINORSTART="$(awk -F '.' '{ print $2 }' lastbuilt)"
    PATCHSTART="$(awk -F '.' '{ print $3 }' lastbuilt)"
    if [ -n "$MAJORCHANGE" ]; then
        NEWMAJOR="$(( MAJORSTART + 1 ))"
        NEWMINOR="0"
        NEWPATCH="0"
    elif [ -n "$MINORCHANGE" ]; then
        NEWMAJOR="$MAJORSTART"
        NEWMINOR="$(( MINORSTART + 1 ))"
        NEWPATCH="0"
    elif [ -n "$PATCHCHANGE" ]; then
        NEWMAJOR="$MAJORSTART"
        NEWMINOR="$MINORSTART"
        NEWPATCH="$(( PATCHSTART + 1 ))"
    fi
    NEWVERSIONTAG="${NEWMAJOR}.${NEWMINOR}.${NEWPATCH}"
    if ! [[ "${d}" =~ ^(./)?01- ]]; then
        SOURCE_IMAGES=$(grep "FROM " ${IMAGENAME} | awk -F ':' '{ print $(NF-1) }' | awk -F '\/' '{ print $NF } ')
        for s in $SOURCE_IMAGES; do
            SOURCE_DIR_VER=$(find ../ -type d -name "*$s*" -exec cat {}/lastbuilt \; )
            sed -i "s/\(FROM\ .*\)$s:.*/\1$s:$SOURCE_DIR_VER/" ${IMAGENAME}
        done
    fi
    docker build --platform="linux/amd64" -t ${BASEREPO}/${IMAGENAME}:${NEWVERSIONTAG} -f ${IMAGENAME} .
    [ $? -eq 0 ] && echo ${NEWVERSIONTAG} > lastbuilt
    # Tag latest for local-dev images. Temporary, we need to streamline a process to be sure what versions with we developed with.
    if [[ "${d}" =~ .+local-dev ]]; then
        docker tag ${BASEREPO}/${IMAGENAME}:${NEWVERSIONTAG} ${BASEREPO}/${IMAGENAME}:latest
    fi
    if [ -z "$LOCAL" ]; then
        docker push ${BASEREPO}/${IMAGENAME}:${NEWVERSIONTAG}
        if [[ "${d}" =~ .+local-dev ]]; then
            docker push ${BASEREPO}/${IMAGENAME}:latest
        fi
    fi
    cd ..
done