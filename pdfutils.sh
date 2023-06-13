#!/bin/zsh

##################################################################
#
# Small ZSH script to perform different actions around PDF files
#
# - Get the number of pages & the mime type
# - List embedded fonts & images
# - Extract embedded images
# - Verify if protected or encrypted
# - Unlock/Decrypt the PDF
#
# Please use at your own risk
#
##################################################################

YELLOW="\033[1;93m"
NOCOLOR="\033[0m"

# Check if Gum is installed, if not, install it
if [[ ! $(which gum) ]] ;
then
    read -p 'gum need to be installed: install it? [Y/n]: ' ANSWER

    if [[ ! $ANSWER || "$ANSWER" == "Y" || "$ANSWER" == "y" ]] ;
    then
        tput sc && brew install gum && tput rc && tput ed
    else
        echo "${YELLOW}Fred's PDF utils${NOCOLOR} cannot work without it."
        exit
    fi
fi

function installApp {
    APP=$1

    if [[ ! $(which brew) ]] ;
    then
        read -p 'Homebrew need to be installed: install it? [Y/n]: ' ANSWER

        if [[ ! $ANSWER || "$ANSWER" == "Y" || "$ANSWER" == "y" ]] ;
        then
            curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
        else
            echo "Please install ${YELLOW}Homebrew${NOCOLOR} or ${YELLOW}$APP${NOCOLOR} manually and run the script again."
            exit
        fi
    fi

    gum confirm "$APP needs to be installed to run this command. Do you want to install it" && tput sc && brew install "$APP" && tput rc && tput ed || echo "$APP not installed: PDF Utils action canceled"
}

function clearLastLine {
    tput cuu 1
    tput el
}

gum style --border normal --margin "1" --padding "1 2" --border-foreground 212 "Welcome to $(gum style --foreground 212 "Fred's PDF utils")"

# If file dosn't exist or not specified, select one
FILE="$1"
if [[ ! $FILE ]] ;
then
    echo "Please ${YELLOW}select${NOCOLOR} a PDF"
    FILE=$(/bin/ls *.pdf | gum choose)
    clearLastLine
elif [[ ! -f "$FILE" ]] ;
then
    echo "File doesn't exist, please select a new PDF"
    FILE=$(/bin/ls *.pdf | gum choose)
    clearLastLine
fi

# Menu of actions on PDF
gum format -- "What do you want to do today?"
ACTION=$(gum choose \
    "1- list embedded fonts" \
    "2- get the number of pages" \
    "3- check mime type" \
    "4- check if protected" \
    "5- list embedded images " \
    "6- extract all embedded images " \
    "7- check if encrypted " \
    "8- unlock/decrypt " \
)

clearLastLine

#
# List the PDF embedded fonts
#
if [[ "$ACTION" == 1-* ]] ;
then
    # Check if Poppler is installed, if not, install it
    if [[ ! $(which pdffonts) ]] ;
    then
        installApp Poppler
    fi

    if [[ $(which pdffonts) ]] ;
    then
        pdffonts "$FILE"
    fi

#
# List the number of pages in the PDF
#
elif  [[ "$ACTION" == 2-* ]] ;
then
    # Not sure why mdls output with a percentage at the end, which isn't a character you can remove
    PAGES=$(mdls -name kMDItemNumberOfPages -raw "$FILE")
    echo "The number of pages is ${YELLOW}$PAGES${NOCOLOR}"

#
# Get the mime type of the PDF
#
elif  [[ "$ACTION" == 3-* ]] ;
then
    TYPE=$(file --mime-type -b "$FILE")
    echo "The mime type is ${YELLOW}$TYPE${NOCOLOR} pages"

#
# Check if the PDF is protected
#
elif  [[ "$ACTION" == 4-* ]] ;
then
    # Check if GhostScript is installed, if not, install it

    if [[ ! $(which gs) ]] ;
    then
        installApp GhostScript
    fi

    if [[ $(which gs) ]] ;
    then
        OUTPUT=$(gs -dBATCH -sNODISPLAY "$FILE" 2>&1 | grep -o "This file requires a password")

        MSG="protected"
        if [[ ! $OUTPUT ]] ;
        then
            MSG="un$MSG"
        fi

        echo "The file is ${YELLOW}$MSG${NOCOLOR}"
    fi

#
# List the PDF embedded images
#
elif [[ "$ACTION" == 5-* ]] ;
then
    # Check if Poppler is installed, if not, install it
    if [[ ! $(which pdfimages) ]] ;
    then
        installApp Poppler
    fi

    if [[ $(which pdfimages) ]] ;
    then
        pdfimages -list "$FILE"
    fi

#
# Extract all the PDF embedded images
#
elif [[ "$ACTION" == 6-* ]] ;
then
    # Check if Poppler is installed, if not, install it
    if [[ ! $(which pdfimages) ]] ;
    then
        installApp Poppler
    fi

    if [[ $(which pdfimages) ]] ;
    then
        pdfimages -all "$FILE" -p pdf-image
        echo "Extracted images:"
        gum style --foreground "#FFFF00" "$(/bin/ls -1 pdf-image*)"
    fi

#
# Check if PDF is encrypted
#
elif [[ "$ACTION" == 7-* ]] ;
then
    # Check if Poppler is installed, if not, install it
    if [[ ! $(which pdfinfo) ]] ;
    then
        installApp Poppler
    fi

    if [[ $(which pdfinfo) ]] ;
    then
        OUTPUT=$(pdfinfo "$FILE" | grep Encrypted | grep yes)

        if [[ $OUTPUT ]] ;
        then
            ALGORITHM=$(echo $OUTPUT | egrep -o 'algorithm:.*[^)]' | sed -n "s/algorithm:/$1/p")

            echo "The file is ${YELLOW}encrypted${NOCOLOR} with the ${YELLOW}$ALGORITHM${NOCOLOR} algorithm:"

            PRINT=$(echo $OUTPUT | egrep -o 'print:\S*' | sed -n "s/print:/$1/p")
            echo "Printing: ${YELLOW}$PRINT${NOCOLOR}"

            COPY=$(echo $OUTPUT | egrep -o 'copy:\S*' | sed -n "s/copy:/$1/p")
            echo "Copying: ${YELLOW}$COPY${NOCOLOR}"

            CHANGE=$(echo $OUTPUT | egrep -o 'change:\S*' | sed -n "s/change:/$1/p")
            echo "Changing: ${YELLOW}$CHANGE${NOCOLOR}"

            NOTES=$(echo $OUTPUT | egrep -o 'addNotes:\S*' | sed -n "s/addNotes:/$1/p")
            echo "Add Notes: ${YELLOW}$NOTES${NOCOLOR}"
        else
            echo "The file is ${YELLOW}not encrypted${NOCOLOR}"
        fi
    fi

#
# Unlock/Decrypt the PDF
#
elif [[ "$ACTION" == 8-* ]] ;
then
    # Check if QPDF is installed, if not, install it
    if [[ ! $(which qpdf) ]] ;
    then
        installApp QPDF
    fi

    if [[ $(which qpdf) ]] ;
    then
        UNLOCKED_FILE="${FILE/.pdf/-unlocked.pdf}"
        gum spin --spinner="line" --title "Unlocking/Decrypting your PDF" -- qpdf -decrypt "$FILE" "$UNLOCKED_FILE"
        echo "File ${YELLOW}$UNLOCKED_FILE${NOCOLOR} unlocked/decrypted"
    fi

# END OF FILE
fi
echo ""
