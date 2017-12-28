#!/bin/bash

# By Xavier "DaScritch" Mouton-Dubosc
# Licence : GPL
# TODO : - Option to restore any jpegs from BACKUP_DIR
# TODO : - Option to process any jpegs from BACKUP_DIR
# TODO : - Indicate size won

# Crash on any bug
set -e

PREFERED_JPEG_QUALITY="high"
MINIMUM_JPEG_QUALITY=75

HELP=$(cat <<-HELP
Usage: optimize_images.sh [OPTIONS] OPTIMIZABLE_DIR [BACKUP_DIR]
Will parse a directory to find optimizable images files, mainly JPEG images.

Parameters:
        -h, --help              Will show this message
        OPTIMIZABLE_DIR         Path to sub directory to scan. Mandatory
        BACKUP_DIR              Path to a backup sub-directory, where files
                                will be copied before processing.                                                                                                                                                                                                                 
                                                                                                                                                                                                                                                                                  
Needed executables :                                                                                                                                                                                                                                                              
        — find                                                                                                                                                                                                                                                                    
        — mozjpeg from mozilla , version > 3.2       https://github.com/mozilla/mozjpeg                                                                                                                                                                                           
        — jpeg-recompress from jpeg-archive > 2.1.1  https://github.com/danielgtaylor/jpeg-archive                                                                                                                                                                                
        — exiftool                                                                                                                                                                                                                                                                
                                                                                                                                                                                                                                                                                  
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
                                                                                                                                                                                                                                                                                  
du -sh ${OPTIMIZABLE_DIR}                                                                                                                                                                                                                                                         
                                                                                                                                                                                                                                                                                  
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
                # Check that BACKUP_DIR is NOT a subdir from OPTIMIZABLE_DIR
        fi
}

# _check_exec cjpeg 
# _check_exec jpeg-recompress
_check_dirs

PROCESSED_FLAG_FILE="${OPTIMIZABLE_DIR}/.last_optimized_images.flag"
RECENTLER_OPTION=""

if [ -f ${PROCESSED_FLAG_FILE} ] ; then
        RECENTLER_OPTION="-anewer ${PROCESSED_FLAG_FILE}"
fi

function _optimize_file() {
        # See https://guides.wp-bullet.com/batch-optimize-jpg-lossy-linux-command-line-with-jpeg-recompress/

        FILENAME=${1}
        echo "— ${FILENAME}"
        DIRNAME=$(dirname "${FILENAME}")
        # replace OPTIMIZABLE_DIR in DIRNAME with BACKUP_DIR
        # jpeg-recompress --quality ${PREFERED_JPEG_QUALITY} --min ${MINIMUM_JPEG_QUALITY} --method smallfry --accurate "${FILENAME}" "${FILENAME}"
        # exiftool -overwrite_original -all= "${FILENAME}"
}

for filename in `find ${OPTIMIZABLE_DIR} -type f -iname "*.jpg" ${RECENTLER_OPTION}` ; do
        # The “for” loop is an obligation, as find -exec command cannot call a shell function
        # I know it may crashes as the response from the find command will be very long
        _optimize_file "${filename}"
done

du -sh ${OPTIMIZABLE_DIR}

touch ${PROCESSED_FLAG_FILE}

