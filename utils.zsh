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
# - If no file with extension, gum choose return nothing
# - No way to go back to previous menus
# - App show let you run another command after you ran one
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
    echo "Please select a ${YELLOW}$1${NOCOLOR}" >&2
    local file=$(/bin/ls *"$2" | gum choose)
    clearLastLine
    echo "$file"
}

# Display error messages
function error {
    echo "${RED}$1"
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

#
# Tooling menu
#
local action=""
gum format -- "What tooling do you want to use utils for?"
local tooling=$(gum choose \
    "1- GitHub" \
    "2- HTTP" \
    "3- Kubernetes" \
    "4- PDF" \
    "5- YouTube" \
    "6- EXIT" \
)
clearLastLine

# GitHub Actions Submenu
if [[ "$tooling" == *"GitHub"* ]] ; then
    gum format -- "What do you to do with GitHub?"
    action=$(gum choose \
        "1- Get user information" \
    )

# HTTP Actions Submenu
elif [[ "$tooling" == *"HTTP"* ]] ; then
    gum format -- "What do you to do with HTTP?"
    action=$(gum choose \
        "1- Find if website is DDoS protected" \
    )

# Kubernetes Actions Submenu
elif [[ "$tooling" == *"Kubernetes"* ]] ; then
    gum format -- "What do you to do with Kubernetes?"
    action=$(gum choose \
        "1- Get ports fowarded" \
    )

# PDF Actions Submenu
elif [[ "$tooling" == *"PDF"* ]] ; then
    gum format -- "What do you to do with the PDF?"
    action=$(gum choose \
        "1- Convert pages to images" \
        "2- Compress PDF (lossless)" \
        "3- List embedded fonts" \
    )


# YouTube Actions Submenu
elif [[ "$tooling" == *"YouTube"* ]] ; then
    gum format -- "What do you to do with YouTube?"
    action=$(gum choose \
        "1- Download a video thumbnail" \
    )
fi

clearLastLine

###########
# Actions #
###########

#
# GitHub: get information about an user
#
if [[ "$tooling" == *"GitHub"* && "$action" == *"Get user information"* ]] ; then
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
        kubectl get svc -o json | jq '.items[] | {name:.metadata.name, p:.spec.ports[] } | select( .p.nodePort != null ) | "\(.name): localhost:\(.p.nodePort) -> \(.p.port) -> \(.p.targetPort)"'
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
            gum format -- "What file?"
            local file=$(gum input --placeholder "/Users/fharper/Downloads/be like batman.pdf")
            mkdir -p pdf-images

            if [[ $file ]] ; then
                echo ""
                local filename=$(basename "$file" .pdf)
                convert -density 300 "$file" -quality 100 "pdf-images/$filename.jpg"
                echo "images are in the pdf-images folder"
            else
                error "No file was entered."
            fi
        fi

    #
    # Compress PDF (lossless)
    #
    elif [[ "$action" == *"Compress PDF (lossless)"* ]] ; then
        if [[ $(which gs | grep "not found" ) ]] ; then
            installApp "Ghostscript" "https://www.ghostscript.com"
        else
            gum format -- "What file?"
            local file=$(gum input --placeholder "/Users/fharper/Downloads/be-like-batman.pdf")

            if [[ $file ]] ; then
                echo ""
                local filename=$(basename "$file" .pdf)
                gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dCompatibilityLevel=1.7 -dNOPAUSE -dQUIET -dPDFSETTINGS=/prepress -sOutputFile="$filename-compressed.pdf"  "$file"
            else
                error "No file was entered."
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
                pdffonts "$file"
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

#
# Quitting
#
elif [[ "$tooling" == *"EXIT"* ]] ; then
    echo "\n"
    say "Goodbye my lover"
    say "Goodbye my friend"
    say "You have been the one"
    say "You have been the one for me"
    echo "\n"
    exit

fi
