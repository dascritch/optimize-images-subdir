#!/bin/bash

# By Xavier "DaScritch" Mouton-Dubosc
# Licence : GPL
# TODO : - Option to restore any jpegs from BACKUP_DIR
# TODO : - Option to process any jpegs from BACKUP_DIR
# TODO : - Indicate size won

# Crash on any bug
set -e

MINIMUM_JPEG_QUALITY=75

HELP=$(cat <<-HELP
Usage: optimize-images-subdir.sh [OPTIONS] OPTIMIZABLE_DIR [BACKUP_DIR]
Will parse a directory to find optimizable images files, mainly JPEG images.

Parameters:
	-h, --help		Will show this message
	OPTIMIZABLE_DIR		Path to sub directory to scan. Mandatory
	BACKUP_DIR		Path to a backup sub-directory, where files
				will be copied before processing.

Needed executables :
	— find

HELP
)

option=${1}

case $option in
	-h|--help)
		echo "$HELP"
		exit 0
	;;
esac

OPTIMIZABLE_DIR=$1
BACKUP_DIR=$2

function _check_dirs() {
	if [ "" == "${OPTIMIZABLE_DIR}" ] ; then
		echo "Missing optimizable directory parameter"
		exit -1
	fi

	if [ ! -d "${OPTIMIZABLE_DIR}" ] ; then
		echo "Inexisting optimizable directory"
		exit -1
	fi

	if [ "" != "${BACKUP_DIR}" ] ; then
		if [ ! -d "${BACKUP_DIR}" ] ; then
		        echo "Inexisting backup directory parameter"
        		exit -1
		fi
	fi
}


_check_dirs

PROCESSED_FLAG_FILE="${OPTIMIZABLE_DIR}/.last_optimized_images.flag"

if [ -f ${PROCESSED_FLAG_FILE} ] ; then
	touch ${PROCESSED_FLAG_FILE}
fi

function _optimize_file() {
	# See https://guides.wp-bullet.com/batch-optimize-jpg-lossy-linux-command-line-with-jpeg-recompress/

	FILENAME=${0}
	jpeg-recompress --quality high --method smallfry --min ${MINIMUM_JPEG_QUALITY} "${FILENAME}" "${FILENAME}"
	exiftool -overwrite_original -all= "${FILENAME}"
}

find ${OPTIMIZABLE_DIR} -type f -iname "*.jpg"
