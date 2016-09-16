#!/bin/sh

# Define the git binary path
if command -v git 1>/dev/null 2>/dev/null; then
    GIT_BIN=`command -v git`
else
    GIT_BIN=git
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
        # Attempt to catch any messages set with the -m, -*m flag
        # Upated to disallow '--' as was incorrectly matching --set-upstream
        elif [[ $i == "-"* && $i != "--"* && $i == *"m" ]]
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
                *)
                        echo "DEFAULT: $GIT_BIN ${theargs}"
                        $GIT_BIN ${theargs}
                        break
                        ;;
        esac
done
