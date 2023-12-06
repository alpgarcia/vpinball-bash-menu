#!/usr/bin/env bash

TBLS_DIR="${HOME}/pinball/tables"
INI_DIR="${HOME}/pinball/ini"
VPINBALL="${HOME}/pinball/vpinball/build/VPinballX_GL"

# TODO - add pagination
# TODO - add default values to the help message

help()
{
    echo "Usage: ./menu.sh [ -t | --tables ]
                 [ -i | --ini ]
                 [ -e | --exe ]
                 [ -h | --help ]"
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

select_file() {

    for((i=0;i<${#files[@]};i++))
    do
        ## Remove common path (get rid of trailing slashes, if any)
        files[$i]="${files[$i]#"$common_path"/*}"
    done

    local valid_opts=""
    ## Add the files to the valid_opts string
    for((i=0;i<${#files[@]};i++))
    do
        ## Remove common path and add the rest to the list
        valid_opts+="${files[$i]}|"
    done

    ## Substitute last | by the closing parenthesis. 
    ## $valid_opts is now @(file1|file2|...|fileN) with paths relative
    ## to TBLS_DIR
    valid_opts="@(${valid_opts%|})"

    ## Show the menu. This will list all files
    select file in "${files[@]}"
    do
        case $file in
        
        ## If the choice is one of the files (if it matches $valid_opts)
        $valid_opts)
            ## Do something here
            echo "$file"
            break;
            ;;
        
        *)
            echo >&2 "Please choose a number from 1 to $((${#files[@]}+1))"       
            ;;
        esac
    done
}

select_vpx() {
    local files=( ${TBLS_DIR}/**/*.vpx )
    local common_path=${TBLS_DIR}
    echo $(select_file)
}

select_ini() {
    local files=( ${INI_DIR}/**/*.ini )
    local common_path=${INI_DIR}
    echo $(select_file)
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

while true
do
    vpx=$(select_vpx)
    echo -e "\nTABLE: ${vpx}\n"
        
    ini=$(select_ini)

    echo -e "\nTABLE: ${vpx}"
    echo -e "\nINI: ${ini}\n"

    echo -e "LAUNCHING...\n"
    (set -x; "${VPINBALL}" -ini "${INI_DIR}/${ini}" -play "${TBLS_DIR}/${vpx}")
    

    echo -e "\n GAME END\n"
done

shopt -u extglob
shopt -u nullglob
shopt -u globstar
