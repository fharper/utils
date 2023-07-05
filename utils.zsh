#!/bin/zsh

##################################################################
#
# ZSH script with a bunch of utilities I created
#
# (mostly making it easier to find how to do something with different CLI)
#
# Dependency:
#  - gum https://github.com/charmbracelet/gum/
#
# Will add my utils little by little
#
# Please use at your own risk
#
# Known issues:
# - If no cluster configuration available to kubectl, let the user know
#
##################################################################

##################
# Configurations #
##################
shortpixel="/Users/fharper/Documents/code/others/shortpixel-php/" # More info at https://github.com/short-pixel-optimizer/shortpixel-php

#############
# Constants #
#############
github_api="https://api.github.com"
YELLOW="\033[1;93m"
RED="\033[0;31m"
NOCOLOR="\033[0m"

#############
# Functions #
#############

# Print something with style
function say {
    gum style --foreground 93 "$1"
}

# Install missing dependency
function installApp {
    local application="$1"
    local website="$2"

    if [[ $(which brew | grep "not found") ]] ;
    then
        read -p 'Homebrew need to be installed: install it? [Y/n]: ' ANSWER

        if [[ ! "$ANSWER" || "$ANSWER" == "Y" || "$ANSWER" == "y" ]] ;
        then
            curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
        else
            print "Please install ${YELLOW}Homebrew${NOCOLOR} or ${YELLOW}$application${NOCOLOR} manually (see $website for instructions) and run the script again."
            exit
        fi
    fi

    local confirmation=$(gum confirm "$application needs to be installed to run this command. Do you want to install it?" && print "true" || print "false")
    if [[ "$confirmation" == "true" ]] ; then
        tput sc
        brew install "$application"
        tput rc
        tput ed
    else
        print "$application not installed. Install it manually (see $website for instructions) and run the script again."
        exit
    fi
}

#Clear last terminal line
function clearLastLine {
    tput cuu 1 >&2
    tput el >&2
}

# Select a file from the running directory
# @param file type (Images, PDFs...)
# @param file extension (.pdf, .png, .jpg). If multiple extensions, use ".png|.jpeg"
function getFile {
    local files=$(/bin/ls | egrep "$2")
    clearLastLine #I cannot get the error output to silence!
    local file;

    if [[ $files ]] ; then
        print "Please select a ${YELLOW}$1${NOCOLOR}" >&2
        file=$(/bin/ls | egrep "$2" | gum choose)
    else
        print "No $1 in this folder: you need to enter the ${YELLOW}full path of the $1${NOCOLOR} manually" >&2
        file=$(gum input --placeholder "/Users/fharper/Downloads/your-file$2")
    fi

    clearLastLine
    print "$file"
}

# Display error messages
function error {
    print "${RED}$1${NOCOLOR}"
}

# Check if PDF is protected
# @param PDF file to check
function isPdfProtected {
    local output=$(gs -dBATCH -sNODISPLAY "$1" 2>&1 | grep -o "This file requires a password")

    local protection="protected"
    if [[ ! $output ]] ; then
        protection="un$protection"
    fi

    print "$protection"
}

##################
# Gum Dependency #
##################

if [[ $(which gum | grep "not found" ) ]] ; then
    installApp "gum" "https://github.com/charmbracelet/gum/"
fi

#########
# Menus #
#########

#
# Welcome message
#
gum style --foreground 212 --border-foreground 212 --border double --align center --width 100 --margin "1 2" --padding "2 4" 'k1-utils' 'With great power comes great responsibility, use carefully!'

while [[ "$tooling" != *"EXIT"* ]] ; do

#
# Tooling menu
#
local action=""
gum format -- "What tooling do you want to use utils for?"
tooling=$(gum choose \
    "1- Any File" \
    "2- Any Image" \
    "3- GitHub" \
    "4- HTTP" \
    "5- Kubernetes" \
    "6- PDF" \
    "8- WAV" \
    "9- YouTube" \
    "10- EXIT" \
)
clearLastLine

# Any Files Submenu
if [[ "$tooling" == *"Any File"* ]] ; then
    gum format -- "What do you to do with the file?"
    action=$(gum choose \
        "1- Get mime type" \
        "↵ Go back" \
    )

# Any Images Submenu
elif [[ "$tooling" == *"Any Image"* ]] ; then
    gum format -- "What do you to do with the image?"
    action=$(gum choose \
        "1- Compress (lossless)" \
        "↵ Go back" \
    )

# GitHub Actions Submenu
elif [[ "$tooling" == *"GitHub"* ]] ; then
    gum format -- "What do you to do with GitHub?"
    action=$(gum choose \
        "1- Get user information" \
        "↵ Go back" \
    )

# HTTP Actions Submenu
elif [[ "$tooling" == *"HTTP"* ]] ; then
    gum format -- "What do you to do with HTTP?"
    action=$(gum choose \
        "1- Find if website is DDoS protected" \
        "↵ Go back" \
    )

# Kubernetes Actions Submenu
elif [[ "$tooling" == *"Kubernetes"* ]] ; then
    gum format -- "What do you to do with Kubernetes?"
    action=$(gum choose \
        "1- Get ports fowarded" \
        "↵ Go back" \
    )

# PDF Actions Submenu
elif [[ "$tooling" == *"PDF"* ]] ; then
    gum format -- "What do you to do with the PDF?"
    action=$(gum choose \
        "1- Check if encrypted" \
        "2- Check if protected" \
        "3- Compress (lossless)" \
        "4- Convert pages to images" \
        "5- Crack protected" \
        "6- Decrypt" \
        "7- Extract embedded images" \
        "8- List embedded fonts" \
        "9- List embedded images" \
        "10- List number of pages" \
        "↵ Go back" \
    )

# WAV Actions Submenu
elif [[ "$tooling" == *"WAV"* ]] ; then
    gum format -- "What do you to do with the WAV file?"
    action=$(gum choose \
        "1- Convert to MP3" \
        "↵ Go back" \
    )

# YouTube Actions Submenu
elif [[ "$tooling" == *"YouTube"* ]] ; then
    gum format -- "What do you to do with YouTube?"
    action=$(gum choose \
        "1- Download a video thumbnail" \
        "↵ Go back" \
    )

# If empty, Ctrl + C was selected (for whatever I cannot trap SIGINT)
else
    tooling="EXIT"
fi

clearLastLine

###########
# Actions #
###########

#
# Any File: Get mime type
#
if [[ "$tooling" == *"Any File"* && "$action" == *"Get mime type"* ]] ; then
    local file=$(getFile "file" "")

    if [[ $file ]] ; then
        local type=$(file --mime-type -b "$file")
        print "The mime type is ${YELLOW}$type${NOCOLOR}\n"
    else
        error "No file was selected."
    fi

#
# Any Image: Compress (lossless)
#
elif [[ "$tooling" == *"Any Image"* && "$action" == *"Compress (lossless)"* ]] ; then

    if [[ $(which php | grep "not found" ) ]] ; then
        installApp "php" "https://github.com/php/php-src"
    elif [[ -z "${SHORTPIXEL_API}" ]] ; then
        print "Please set the SHORTPIXEL_API environment variable with your ShortPixel API Key."
    else
        local file=$(getFile "file" ".png|.jpeg|.jpg|.gif|.bmp|.tiff")

        if [[ $file ]] ; then
            local filename="${file%.*}"
            local extension="${file##*.}"

            # Since ShortPixel only optimize a folder, we need to move the file to its own folder
            local folder="/tmp/shortpixel-$RANDOM/"
            mkdir "$folder"
            cp "$file" "$filename.backup.$extension"
            mv "$file" "$folder"

            # Optimize the image
            php "$shortpixel"lib/cmdShortpixelOptimize.php --apiKey="$SHORTPIXEL_API" --compression=0 --clearLock --folder="$folder"

            # Move back the image
            mv "$folder$file" .
            rm -rf "$folder"
        else
            error "No file was selected."
        fi
    fi

#
# GitHub: get information about an user
#
elif [[ "$tooling" == *"GitHub"* && "$action" == *"Get user information"* ]] ; then
    if [[ $(which curl | grep "not found" ) ]] ; then
        installApp "curl" "https://github.com/curl/curl"
    fi

    if [[ $(which jq | grep "not found" ) ]] ; then
            installApp "jq" "https://github.com/jqlang/jq"
    fi

    gum format -- "Which username?"
    local username=$(gum input --placeholder "fharper")
    clearLastLine

    if [[ $username ]] ; then
        print ""
        curl -sS -H "Authorization: Bearer $GITHUB_TOKEN" "$github_api/users/$username" | jq '.name, .email, .blog' | tr -d '"' && curl -sS -H "Authorization: Bearer $GITHUB_TOKEN" "$github_api/users/$username/social_accounts" | jq '.[] .url' | tr -d '"'
    else
        error "No username was entered."
    fi

#
# HTTP: find if website is DDoS protected
#
elif [[ "$tooling" == *"HTTP"* && "$action" == *"Find if website is DDoS protected"* ]] ; then
    if [[ $(which curl | grep "not found" ) ]] ; then
        installApp "curl" "https://github.com/curl/curl"
    else
        gum format -- "Which site?"
        local site=$(gum input --placeholder "https://fred.dev")

        if [[ $site ]] ; then
            print ""
            curl -sSI "$site" | grep -E 'cloudflare|Pantheon' || print "Nope"
        else
            error "No site was entered."
        fi
    fi

#
# Kubernetes: get ports forwarded from a cluster
#
elif [[ "$tooling" == *"Kubernetes"* && "$action" == *"Get ports fowarded"* ]] ; then
    if [[ $(which kubectl | grep "not found" ) ]] ; then
        installApp "kubectl" "https://github.com/kubernetes/kubectl"
    else
        local result=$(kubectl get svc -o json | jq '.items[] | {name:.metadata.name, p:.spec.ports[] } | select( .p.nodePort != null ) | "\(.name): localhost:\(.p.nodePort) -> \(.p.port) -> \(.p.targetPort)"')

        if [[ ! "$result" ]] ; then
            error "No ports are forwarded.\n"
        fi
    fi

#
# PDF
#
elif [[ "$tooling" == *"PDF"* ]] ; then

    #
    # Convert pages to images
    #
    if [[ "$action" == *"Convert pages to images"* ]] ; then
        if [[ $(which convert | grep "not found" ) ]] ; then
            installApp "ImageMagick" "https://github.com/ImageMagick/ImageMagick"
        else
            local file=$(getFile "PDF" ".pdf")

            if [[ $file ]] ; then
                print ""
                local filename=$(basename "$file" .pdf)
                mkdir -p pdf-images

                convert -density 300 "$file" -quality 100 "pdf-images/$filename.jpg"
                print "images are in the pdf-images folder"
            else
                error "No file was selected."
            fi
        fi

    #
    # Compress PDF (lossless)
    #
    elif [[ "$action" == *"Compress (lossless)"* ]] ; then
        if [[ $(which gs | grep "not found" ) ]] ; then
            installApp "Ghostscript" "https://www.ghostscript.com"
        else
            local file=$(getFile "PDF" ".pdf")

            if [[ $file ]] ; then
                print ""
                local filename=$(basename "$file" .pdf)
                gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dCompatibilityLevel=1.7 -dNOPAUSE -dQUIET -dPDFSETTINGS=/prepress -sOutputFile="$filename-compressed.pdf"  "$file"
            else
                error "No file was selected."
            fi
        fi

    #
    # List embedded fonts
    #
    elif [[ "$action" == *"List embedded fonts"* ]] ; then

        if [[ $(which pdffonts | grep "not found" ) ]] ; then
            installApp "Poppler" "https://poppler.freedesktop.org"
        else
            local file=$(getFile "PDF" ".pdf")

            if [[ $file ]] ; then
                print ""
                pdffonts "$file"
            else
                error "No file was selected."
            fi
        fi

    #
    # List number of page
    #
    elif [[ "$action" == *"List number of pages"* ]] ; then
        local file=$(getFile "PDF" ".pdf")

        if [[ $file ]] ; then
            print ""
            local pages=$(mdls -name kMDItemNumberOfPages -raw "$file")
            print "The number of pages is ${YELLOW}$pages${NOCOLOR}\n"
        else
            error "No file was selected."
        fi

    #
    # Check if protected
    #
    elif [[ "$action" == *"Check if protected"* ]] ; then
        if [[ $(which gs | grep "not found" ) ]] ; then
            installApp "Ghostscript" "https://www.ghostscript.com"
        else
            local file=$(getFile "PDF" ".pdf")

            if [[ $file ]] ; then
                print ""
                protection=$(isPdfProtected "$file")

                print "The file is ${YELLOW}$protection${NOCOLOR}\n"
            else
                error "No file was selected."
            fi
        fi

    #
    # List embedded images
    #
    elif [[ "$action" == *"List embedded images"* ]] ; then

        if [[ $(which pdfimages | grep "not found" ) ]] ; then
            installApp "Poppler" "https://poppler.freedesktop.org"
        else
            local file=$(getFile "PDF" ".pdf")

            if [[ $file ]] ; then
                print ""
                pdfimages -list "$file"
                print ""
            else
                error "No file was selected."
            fi
        fi

    #
    # Extract embedded images
    #
    elif [[ "$action" == *"Extract embedded images"* ]] ; then

        if [[ $(which pdfimages | grep "not found" ) ]] ; then
            installApp "Poppler" "https://poppler.freedesktop.org"
        else
            local file=$(getFile "PDF" ".pdf")

            if [[ $file ]] ; then
                print ""
                pdfimages -all "$file" -p pdf-image
                print "Extracted images:"
                gum style --foreground "#FFFF00" "$(/bin/ls -1 pdf-image*)"
                print ""
            else
                error "No file was selected."
            fi
        fi

    #
    # Check if encrypted
    #
    elif [[ "$action" == *"Check if encrypted"* ]] ; then

        if [[ $(which pdfinfo | grep "not found" ) ]] ; then
            installApp "Poppler" "https://poppler.freedesktop.org"
        else
            local file=$(getFile "PDF" ".pdf")

            if [[ $file ]] ; then
                print ""
                local output=$(pdfinfo "$file" | grep Encrypted | grep yes)

                if [[ $output ]] ; then
                    local algorithm=$(print $output | egrep -o 'algorithm:.*[^)]' | sed -n "s/algorithm:/$1/p")

                    print "The file is ${YELLOW}encrypted${NOCOLOR} with the ${YELLOW}$algorithm${NOCOLOR} algorithm:"

                    local print=$(print $output | egrep -o 'print:\S*' | sed -n "s/print:/$1/p")
                    print "Printing: ${YELLOW}$print${NOCOLOR}"

                    local copy=$(print $output | egrep -o 'copy:\S*' | sed -n "s/copy:/$1/p")
                    print "Copying: ${YELLOW}$copy${NOCOLOR}"

                    local change=$(print $output | egrep -o 'change:\S*' | sed -n "s/change:/$1/p")
                    print "Changing: ${YELLOW}$change${NOCOLOR}"

                    local notes=$(print $output | egrep -o 'addNotes:\S*' | sed -n "s/addNotes:/$1/p")
                    print "Add Notes: ${YELLOW}$notes${NOCOLOR}"
                else
                    print "The file is ${YELLOW}not encrypted${NOCOLOR}"
                fi

                print ""
            else
                error "No file was selected."
            fi
        fi

    #
    # Decrypt
    #
    elif [[ "$action" == *"Decrypt"* ]] ; then

        if [[ $(which qpdf | grep "not found" ) ]] ; then
            installApp "qpdf" "https://github.com/qpdf/qpdf"
        else
            local file=$(getFile "PDF" ".pdf")

            if [[ $file ]] ; then
                print ""
                if [[ $(isPdfProtected "$file") == "protected" ]] ; then
                    error "The PDF is protected: you need to remove the protection first."
                    print ""
                else
                    local filename=$(basename "$file" .pdf)
                    local unlocked_file="$filename-unlocked.pdf"
                    qpdf -decrypt "$file" "$unlocked_file"
                    print "File ${YELLOW}$unlocked_file${NOCOLOR} unlocked/decrypted"
                    print ""
                fi
            else
                error "No file was selected."
            fi
        fi

    #
    # Crack protected
    #
    elif [[ "$action" == *"Crack protected"* ]] ; then

        if [[ $(which pdfcrack | grep "not found" ) ]] ; then
            installApp "pdfcrack" "https://sourceforge.net/projects/pdfcrack/"
        else
            local confirmation=$(gum confirm "Is it on a PDF you own or have the right to view but lost the password?" && print "true" || print "false")

            if [[ $confirmation == "true" ]] ; then

                local file=$(getFile "PDF" ".pdf")

                if [[ $file ]] ; then
                    print ""
                    pdfcrack -f "$file"
                    print ""
                else
                    error "No file was selected."
                fi
            fi
        fi

    fi

#
# WAV: Convert to MP3
#
elif [[ "$tooling" == *"WAV"* && "$action" == *"Convert to MP3"* ]] ; then

    if [[ $(which ffmpeg | grep "not found" ) ]] ; then
        installApp "ffmpeg" "https://github.com/FFmpeg/FFmpeg"
    else
        local file=$(getFile "WAV" ".wav")

        if [[ $file ]] ; then
            print ""
            ffmpeg -i "$file" -acodec libmp3lame "${file/%wav/mp3}";
            print ""
        else
            error "No file was selected."
        fi
    fi

#
# YouTube: download a video thumbnail
#
elif [[ "$tooling" == *"YouTube"* && "$action" == *"Download a video thumbnail"* ]] ; then
    gum format -- "Which video?"
    local video=$(gum input --placeholder "https://www.youtube.com/watch?v=-8pX4ayi_XY")

    if [[ $video ]] ; then
        id=$(print "$video" | sed 's/.*v=//g')
        curl "https://img.youtube.com/vi/$id/maxresdefault.jpg" > youtube_video_thumbnail.jpg
    else
        error "No video URL was entered."
    fi

fi
done

#
# Quitting
#
    print "\n"
    say "Goodbye my lover"
    say "Goodbye my friend"
    say "You have been the one"
    say "You have been the one for me"
    print "\n"
    exit
