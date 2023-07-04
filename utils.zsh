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
local github_api="https://api.github.com"

##########
# Colors #
##########
YELLOW="\033[1;93m"
RED="\033[0;31m"
NOCOLOR="\033[0m"

#############
# Functions #
#############

# Echo something with style
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
            echo "Please install ${YELLOW}Homebrew${NOCOLOR} or ${YELLOW}$application${NOCOLOR} manually (see $website for instructions) and run the script again."
            exit
        fi
    fi

    local confirmation=$(gum confirm "$application needs to be installed to run this command. Do you want to install it?" && echo "true" || echo "false")
    if [[ "$confirmation" == "true" ]] ; then
        tput sc
        brew install "$application"
        tput rc
        tput ed
    else
        echo "$application not installed. Install it manually (see $website for instructions) and run the script again."
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
# @param file extension (.pdf, .png, .jpg)
function getFile {
    local files=$(/bin/ls *"$2")
    clearLastLine #I cannot get the error output to silence!
    local file;

    if [[ $files ]] ; then
        echo "Please select a ${YELLOW}$1${NOCOLOR}" >&2
        file=$(/bin/ls *"$2" | gum choose)
    else
        echo "No $1 in this folder: you need to enter the ${YELLOW}full path of the $1${NOCOLOR} manually" >&2
        file=$(gum input --placeholder "/Users/fharper/Downloads/be-like-batman.pdf")
    fi

    clearLastLine
    echo "$file"
}

# Display error messages
function error {
    echo "${RED}$1${NOCOLOR}"
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
    "2- GitHub" \
    "3- HTTP" \
    "4- Kubernetes" \
    "5- PDF" \
    "6- YouTube" \
    "7- EXIT" \
)
clearLastLine

# Any Files Submenu
if [[ "$tooling" == *"Any File"* ]] ; then
    gum format -- "What do you to do with the file?"
    action=$(gum choose \
        "1- Get mime type" \
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
        "1- Check if protected" \
        "2- Compress PDF (lossless)" \
        "3- Convert pages to images" \
        "4- List embedded fonts" \
        "5- List embedded images" \
        "6- List number of pages" \
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
# Any file: Get mime type
#
if [[ "$tooling" == *"Any File"* && "$action" == *"Get mime type"* ]] ; then
    local file=$(getFile "file" "")

    if [[ $file ]] ; then
        local type=$(file --mime-type -b "$file")
        echo "The mime type is ${YELLOW}$type${NOCOLOR}\n"
    else
        error "No file was selected."
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
        echo ""
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
            echo ""
            curl -sSI "$site" | grep -E 'cloudflare|Pantheon' || echo "Nope"
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
                echo ""
                local filename=$(basename "$file" .pdf)
                mkdir -p pdf-images

                convert -density 300 "$file" -quality 100 "pdf-images/$filename.jpg"
                echo "images are in the pdf-images folder"
            else
                error "No file was selected."
            fi
        fi

    #
    # Compress PDF (lossless)
    #
    elif [[ "$action" == *"Compress PDF (lossless)"* ]] ; then
        if [[ $(which gs | grep "not found" ) ]] ; then
            installApp "Ghostscript" "https://www.ghostscript.com"
        else
            local file=$(getFile "PDF" ".pdf")

            if [[ $file ]] ; then
                echo ""
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
                echo ""
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
            echo ""
            local pages=$(mdls -name kMDItemNumberOfPages -raw "$file")
            echo "The number of pages is ${YELLOW}$pages${NOCOLOR}\n"
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
                echo ""
                local output=$(gs -dBATCH -sNODISPLAY "$file" 2>&1 | grep -o "This file requires a password")

                local protection="protected"
                if [[ ! $output ]] ;
                then
                    protection="un$protection"
                fi

                echo "The file is ${YELLOW}$protection${NOCOLOR}\n"
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
                echo ""
                pdfimages -list "$file"
                echo ""
            else
                error "No file was selected."
            fi
        fi

    fi
#
# YouTube: download a video thumbnail
#
elif [[ "$tooling" == *"YouTube"* && "$action" == *"Download a video thumbnail"* ]] ; then
    gum format -- "Which video?"
    local video=$(gum input --placeholder "https://www.youtube.com/watch?v=-8pX4ayi_XY")

    if [[ $video ]] ; then
        id=$(echo "$video" | sed 's/.*v=//g')
        curl "https://img.youtube.com/vi/$id/maxresdefault.jpg" > youtube_video_thumbnail.jpg
    else
        error "No video URL was entered."
    fi
fi

done

#
# Quitting
#
    echo "\n"
    say "Goodbye my lover"
    say "Goodbye my friend"
    say "You have been the one"
    say "You have been the one for me"
    echo "\n"
    exit
