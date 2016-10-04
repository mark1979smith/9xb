#!/bin/sh

# Define the git binary path
if command -v git 1>/dev/null 2>/dev/null; then
    GIT_BIN=`command -v git`
    PHP_BIN=`command -v php`
else
    GIT_BIN=git
    PHP_BIN=php
fi

################
### FUNCTIONS ##
################

function displayConflicts {
        out=$($GIT_BIN diff --name-only --diff-filter=U)
        outLength=${#out}
        if [[ $outLength > 0 ]]
        then
            tput setaf 4
            echo "Conflicts exist in files."
            echo "Please resolve before continuing"
            tput setaf 1
            for file in $out
            do
                echo $file
            done
            tput sgr0
        fi
}


# Now normalise the options that have been passed into this script
# to ensure that quotes are around any arguments that need them
theargs=""
storemessage=0
message=""

# Iterate over the arguments looking for -m (or any variation of)
# and setting the naxt argument as the message
while read -r cmd; do
    for i in "$@"
    do
        if [[ $storemessage == 1 ]]
        then
            # Ignore values with Whitespace as GIT complains due to quotes being removed
            message=$i
            storemessage=0
        elif [[ $i == "-"* && $i == *"m" ]]
        then
            # ignore this as we add it seperately
            storemessage=1
        else
            theargs="${theargs} $i"
        fi
    done
done <<< "$@"

while test $# -gt 0; do
        case "$1" in
                commit)
                        out=$($GIT_BIN diff --name-only --diff-filter=U)
                        outLength=${#out}
                        if [[ $outLength > 0 ]]
                        then
                                displayConflicts
                        else
                            messageLength=${#message}
                            if [[ $messageLength == 0 ]]
                            then
                                $GIT_BIN ${theargs}
                            else
                                $GIT_BIN ${theargs} -m "$message"
                            fi
                        fi
                        exit 0
                        ;;
                merge)
                        # Issue command
                        $GIT_BIN ${theargs}

                        displayConflicts

                        exit 0
                        ;;
                push)
                        out="$($GIT_BIN ls-files --others --exclude-standard)"
                        outLength=${#out}
                        if [[ $outLength > 0 ]]; then
                            tput setaf 1
                            echo "Warning: You have untracked files. Consider adding this files to your .gitignore file"
                            tput setaf 3
                            while read -r o; do
                                echo $o
                            done <<< "$out"
                            tput setaf 4
                            read -p "Would you like to continue? [Y/N]" pushChoice
                            tput sgr0
                            if [[ $pushChoice == "N" || $pushChoice == "n" ]]; then
                                tput setaf 2
                                echo "Push Cancelled"
                                tput sgr0
                                exit 0
                            fi
                        fi
                        $GIT_BIN ${theargs}
                        exit 0
                        ;;
                add)
                        for i in "$@"
                        do
                                if [ "$i" = "$1" ]
                                then
                                        continue
                                fi
                                if [[ $i == *".ph"* ]]; then
                                    tput setaf 1
                                    out="$($PHP_BIN -l $i)"
                                    tput sgr 0
                                    if [[ $out == "Errors parsing "* ]]; then
                                            tput setaf 3
                                            echo $out
                                            tput sgr 0
                                    else
                                            tput setaf 2
                                            echo $out
                                            tput sgr 0

                                            $GIT_BIN $1 $i
                                    fi
                                else 
                                    $GIT_BIN $1 $i
                                fi
                        done
                        exit 0
                        ;;
                self-update)
                        echo "Performing self-update..."
                        wget --quiet --output-document=$0.tmp http://bit.ly/2dOAc6m
                         # Copy over modes from old version
                        OCTAL_MODE=$(stat -c '%a' $0)
                        chmod $OCTAL_MODE $0.tmp

                        case ${OCTAL_MODE:--1} in
                           -[1] )
                                printf "Error : OCTAL_MODE was empty\n"
                                exit 1
                                ;;
                           777|775|755 ) : nothing ;;
                           * )
                                printf "Error in OCTAL_MODEs, found value=${OCTAL_MODE}\n"
                                exit 1
                                ;;
                        esac

                        if  ! chmod $OCTAL_MODE $0.tmp ; then
                                echo "error on chmod $OCTAL_MODE %0.tmp, can't continue"
                                exit 1
                        fi
                        
                        mv $0.tmp "$0":
                        exit 0
                        ;;

                *)
                        echo "DEFAULT: $GIT_BIN ${theargs}"
                        $GIT_BIN ${theargs}
                        break
                        ;;
        esac
done
