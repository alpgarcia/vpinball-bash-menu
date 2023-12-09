#!/usr/bin/env bash

TBLS_DIR="${HOME}/pinball/tables"
INI_DIR="${HOME}/pinball/ini"
VPINBALL="${HOME}/pinball/vpinball/build/VPinballX_GL"
CHUNK_SIZE=20

## Text formatting
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
GREY=$(tput setaf 8)
GREEN=$(tput setaf 2)
OLIVE=$(tput setaf 3)
BLUE=$(tput setaf 4)


help()
{
    printf "Usage: ./menu.sh [ -t | --tables <TABLES_ROOT_DIR>] (default: ${TBLS_DIR})\n"
    printf "\t\t [ -i | --ini <INI_FILES_ROOT_DIR>] (default: ${INI_DIR})\n"
    printf "\t\t [ -e | --exe <VPINBALL_BINARY_PATH>] (default: ${VPINBALL})\n"
    printf "\t\t [ -p | --page-size <NUMBER_OF_ITEMS_PER_PAGE>] (default: ${CHUNK_SIZE})\n"
    printf "\t\t [ -h | --help ]\n"
    exit 2
}

parse_args() {

    if [ $# -gt 6 ]; then
        help
    fi

    while [[ $# -gt 0 ]]
    do
        key="$1"
        case $key in
            -t|--tables)
                TBLS_DIR="$2"
                shift 2 # past argument and value
                ;;
            -i|--ini)
                INI_DIR="$2"
                shift 2 # past argument and value
                ;;
            -p | --page-size)
                CHUNK_SIZE="$2"
                shift 2 # past argument and value
                ;;
            -e|--exe)
                VPINBALL="$2"
                shift 2 # past argument and value
                ;;
            -h|--help)
                help
                ;;
            *)    # unknown option
                help
                ;;
        esac
    done
}

sidecar_info() {
    if [[ -f "${chunk[$i]%.vpx}.ini" ]]; then
        side+="${BOLD}${GREEN}i${NORMAL}${GREY}·"
    else
        side+="${GREY}i${GREY}·"
    fi
    if [[ -f "${chunk[$i]%.vpx}.directb2s" ]]; then
        side+="${BOLD}${OLIVE}b${NORMAL}${GREY}·"
    else
        side+="${GREY}b${GREY}·"
    fi
    if [[ -f "${chunk[$i]%.vpx}.vbs" ]]; then
        side+="${BOLD}${BLUE}v${NORMAL}"
    else
        side+="${GREY}v${NORMAL}"
    fi
}

select_file() {

    local num_files=${#files[@]}

    ## Show the menu. This will list current chunk
    # Limit the number of columns to 1
    COLUMNS=1
    local selected=false
    until ${selected};
    do
        # Clear the screen preserving the scrollback buffer
        clear -x

        # Get files to display
        chunk=("${files[@]:INDEX:CHUNK_SIZE}")

        # Print header with pagination info
        local pos=$((INDEX+1))
        local end=$((INDEX+${#chunk[@]}))
        printf "${BOLD}\n-----\n" >&2
        printf "${title} ${pos} - ${end} of ${num_files}\n" >&2
        printf "${NORMAL}n - Next page, p - Previous page, Ctrl+C - Exit\n" >&2
        printf "${BOLD}%s\n\n${NORMAL}" "-----" >&2

        # Print the options: for each file in the chunk, print the order
        # number and the file name
        for((i=0;i<${#chunk[@]};i++))
        do
            # Look for sidecar files if vpx extension
            local side=""
            if [[ ${chunk[$i]} == *.vpx ]]; then
                side="["
                sidecar_info
                side+="] "
            fi
            
            # Remove common path (get rid of trailing slashes, if any)
            chunk[$i]="${chunk[$i]#"$common_path"/*}"

            # Print the order number (formatted to the lenght of the number
            # of files) and the file path (common path removed) without extension.
            printf "[%${#num_files}d] %s%s\n" "$((i+1))" "${side}" "${chunk[$i]%.*}" >&2

        done

        printf "\n ${BOLD}%s${NORMAL}" "${PS3-#? }" >&2
        read -r

        # If the user types 'n', go to the next page
        if [[ $REPLY = n ]]; then
            if [[ $((INDEX+CHUNK_SIZE)) -le ${num_files} ]]; then
               INDEX=$((INDEX+CHUNK_SIZE))    
            fi

        # If the user types 'p', go to the previous page
        elif [[ $REPLY = p ]]; then
            if [[ $((INDEX-CHUNK_SIZE)) -ge 0 ]]; then
                INDEX=$((INDEX-CHUNK_SIZE))
            fi
        
        elif [[ $REPLY -ge 1 && $REPLY -le $end ]]; then
            FILE_PATH=${chunk[$((REPLY-1))]}
            selected=true

        fi

    done

}

select_vpx() {
    PS3="Select a table to play: "

    local title="TABLES"
    local files=( ${TBLS_DIR}/**/*.vpx )
    local common_path=${TBLS_DIR}
    select_file
}

select_ini() {
    PS3="Select an ini file to use: "

    local title="TABLE: ${VPX}\nINI FILES "
    local files=( ${INI_DIR}/**/*.ini )
    local common_path=${INI_DIR}
    select_file
}


## Enable extended globbing. This lets us use @(foo|bar) to
## match either 'foo' or 'bar'.
shopt -s extglob

## Include dot files 
#shopt -s dotglob

## Remove unmatched patterns from the list. Used to avoid
## including "*.vpx" in "$files" when no vpx files are found.
shopt -s nullglob
## Enable recursive globbing. This lets us use the **
shopt -s globstar

parse_args "$@"

INDEX=0
TABLE_INDEX=0
INI_INDEX=0
while true
do
    INDEX=${TABLE_INDEX}
    select_vpx
    VPX=$FILE_PATH
    TABLE_INDEX=${INDEX}
    
    INDEX=${INI_INDEX}
    select_ini
    INI=$FILE_PATH
    INI_INDEX=${INDEX}

    printf "\n-----\n" >&2
    printf "TABLE: ${VPX}\n" >&2
    printf "INI: ${INI}\n" >&2
    printf "%s\n" "-----" >&2

    printf "LAUNCHING...\n" >&2
    (set -x; "${VPINBALL}" -ini "${INI_DIR}/${INI}" -play "${TBLS_DIR}/${VPX}" >&2)
    
    printf "\n-----" >&2
    printf "GAME END\n" >&2
    printf "%s\n" "-----" >&2
done

shopt -u extglob
shopt -u nullglob
shopt -u globstar

unset PS3
