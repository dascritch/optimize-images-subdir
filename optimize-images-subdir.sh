#!/bin/bash

# By Xavier "DaScritch" Mouton-Dubosc , 2017
# Licence : GPL 3.0
# Distribution : https://github.com/dascritch/optimize-images-subdir
# Original idea : https://guides.wp-bullet.com/batch-optimize-jpg-lossy-linux-command-line-with-jpeg-recompress/
#
# TODO : - Option to restore any jpegs from BACKUP_DIR
# TODO : - Option to process any jpegs from BACKUP_DIR


HELP=$(cat <<-HELP
Usage: optimize-image-subdir.sh [OPTIONS] OPTIMIZABLE_DIR [BACKUP_DIR]
Will parse a directory to find optimizable images files, mainly JPEG images.

Parameters:
    -h, --help          Show this message.
    -v, --verbose       Write before and after sizes for each processed files.
    -s, --simulate      Only logs impactable images.
    -a, --all           Process any images. 
                        Default : Process only on images newer than last run.
    OPTIMIZABLE_DIR     Path to sub directory to scan. Mandatory.
    BACKUP_DIR          Path to a backup sub-directory, where files will be 
                        copied before processing.
                        You SHOULD use this option, or have a backup elsewhere.

Watch out ! 
    — You must have write rights on any images in the subdir. May be helpful:
        sudo chown -R (you) OPTIMIZABLE_DIR                                                                                             
        sudo chmod -R u+w OPTIMIZABLE_DIR                                                                                               
    — Create the BACKUP_DIR before use it via the script. This limitation is                                                            
        intentional.                                                                                                                    
                                                                                                                                        
Needed executables :                                                                                                                    
    — find                                                                                                                              
    — mozjpeg from mozilla , version > 3.2       https://github.com/mozilla/mozjpeg                                                     
    — jpeg-recompress from jpeg-archive > 2.1.1  https://github.com/danielgtaylor/jpeg-archive                                          
    — exiftool                                                                                                                          
                                                                                                                                        
HELP                                                                                                                                    
)                                                                                                                                       
                                                                                                                                        
PREFERED_JPEG_QUALITY="medium"                                                                                                          
MINIMUM_JPEG_QUALITY=75                                                                                                                 
SIMULATE="n"                                                                                                                            
NEWER="y"                                                                                                                               
VERBOSE="n"                                                                                                                             
                                                                                                                                        
# Crash on any bug                                                                                                                      
set -e                                                                                                                                  
                                                                                                                                        
while [ '-' == ${1:0:1} ] ; do                                                                                                          
        case ${1} in                                                                                                                    
                -h|--help)                                                                                                              
                        echo "${HELP}"                                                                                                  
                        exit 0                                                                                                          
                ;;                                                                                                                      
                -v|--verbose)                                                                                                           
                        VERBOSE="y"                                                                                                     
                ;;                                                                                                                      
                -s|--simulate)                                                                                                          
                        SIMULATE="y"                                                                                                    
                ;;                                                                                                                      
                -a|--all)                                                                                                               
                        NEWER="n"                                                                                                       
                ;;                                                                                                                      
                --)
                        shift
                        break
                ;;
        esac
        shift
done


OPTIMIZABLE_DIR=${1}
BACKUP_DIR=${2}

function _check_dirs() {
        if [ "" == "${OPTIMIZABLE_DIR}" ] ; then
                echo "Missing mandatory parameter"
                exit -1
        fi
        OPTIMIZABLE_DIR=$(realpath ${OPTIMIZABLE_DIR})

        if [ ! -d "${OPTIMIZABLE_DIR}" ] ; then
                echo "Inexisting optimizable directory ${OPTIMIZABLE_DIR}"
                exit -1
        fi

        if [ "" != "${BACKUP_DIR}" ] ; then
                BACKUP_DIR=$(realpath ${BACKUP_DIR})

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

if [ "y" == ${VERBOSE} ] ; then
        echo "Total for directory before : $(du -sh ${OPTIMIZABLE_DIR})"
fi

PROCESSED_FLAG_FILE="${OPTIMIZABLE_DIR}/.last_optimized_images.flag"

RECENTLER_OPTION=""
if [ "y" == ${NEWER} ] && [ -f ${PROCESSED_FLAG_FILE} ] ; then
        RECENTLER_OPTION="-anewer ${PROCESSED_FLAG_FILE}"
fi

function _optimize_file() {
        FILENAME=${1}
        function _size_report() {
                if [ "n" == ${VERBOSE} ] ; then
                        return
                fi
                _size=$(du --bytes -- "${FILENAME}")
                echo "        ${1} size : ${_size/${FILENAME}/} "
        }

        _size_report original
        if [ "y" == ${SIMULATE} ] ; then
                return
        fi
        jpeg-recompress --quality ${PREFERED_JPEG_QUALITY} --min ${MINIMUM_JPEG_QUALITY} --method smallfry --accurate "${FILENAME}" "${FILENAME}"
        exiftool -overwrite_original -all= "${FILENAME}"
        _size_report processed
}

function _process_file() {
        # See https://guides.wp-bullet.com/batch-optimize-jpg-lossy-linux-command-line-with-jpeg-recompress/
        FILENAME=${1}
        BACKUP_FILENAME=${FILENAME/$OPTIMIZABLE_DIR/$BACKUP_DIR}
        if [ 'y' == ${VERBOSE} ] ; then
                echo 
                echo "${FILENAME}"
        fi
        if [ "n" == ${SIMULATE} ] && [ "" != "${BACKUP_DIR}" ] ; then
                BACKUP_DIRNAME=$(dirname "${BACKUP_FILENAME}")
                if [ "y" == ${VERBOSE} ] ; then
                        echo "        copied to ${BACKUP_FILENAME} "
                fi
                if [ "n" == ${SIMULATE} ] ; then
                        mkdir -p "${BACKUP_DIRNAME}"
                        cp "${FILENAME}" "${BACKUP_FILENAME}"
                fi
        fi
        _optimize_file ${FILENAME}
}

for filename in `find ${OPTIMIZABLE_DIR} -type f -iname "*.jpg" ${RECENTLER_OPTION}` ; do
        # The “for” loop is an obligation, as find -exec command cannot call a shell function
        # I know it may crashes as the response from the find command will be very long
        _process_file "${filename}"
done

if [ "y" == ${VERBOSE} ] ; then
        echo "Total for directory after : $(du -sh ${OPTIMIZABLE_DIR})"
fi

touch ${PROCESSED_FLAG_FILE}

