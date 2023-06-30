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
function say {
    gum style --foreground 93 "$1"
}

################
# Dependencies #
################

# Gum
# https://github.com/charmbracelet/gum/
if [[ -n $(which gum >/dev/null) ]] ;
then
    echo "gum is used to give a better experience. Would you like to ${YELLOW}install it using Homebrew${NOCOLOR}? [Y/n] "
    read -r ANSWER

    if [[ ! $ANSWER || "$ANSWER" == "Y" || "$ANSWER" == "y" ]] ;
    then
        tput sc && brew install gum && tput rc && tput ed
    else
        echo "This script ${YELLOW}cannot work${NOCOLOR} without this utility. Find alternative ways to install it at https://github.com/charmbracelet/gum/."
        exit
    fi
fi

# kubectl
# https://github.com/charmbracelet/gum/
if [[ -n $(which kubectl >/dev/null) ]] ;
then
    echo "kubectl is used for the Kubernetes utilities. Would you like to ${YELLOW}install it using Homebrew${NOCOLOR}? [Y/n] "
    read -r ANSWER

    if [[ ! $ANSWER || "$ANSWER" == "Y" || "$ANSWER" == "y" ]] ;
    then
        tput sc && brew install kubectl && tput rc && tput ed
    else
        echo "This script ${YELLOW}cannot work${NOCOLOR} without this utility. Find alternative ways to install it at https://github.com/kubernetes/kubectl."
        exit
    fi
fi

# jq
# https://github.com/jqlang/jq
if [[ -n $(which jq >/dev/null) ]] ;
then
    echo "jq is used to parse JSON. Would you like to ${YELLOW}install it using Homebrew${NOCOLOR}? [Y/n] "
    read -r ANSWER

    if [[ ! $ANSWER || "$ANSWER" == "Y" || "$ANSWER" == "y" ]] ;
    then
        tput sc && brew install jq && tput rc && tput ed
    else
        echo "This script ${YELLOW}cannot work${NOCOLOR} without this utility. Find alternative ways to install it at https://github.com/jqlang/jq."
        exit
    fi
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
    "2- Kubernetes" \
    "3- HTTP" \
    "4- PDF" \
    "5- YouTube" \
    "6- EXIT" \
)

# GitHub Actions Submenu
if [[ "$tooling" == *"GitHub"* ]] ; then
    gum format -- "What do you to do with GitHub?"
    action=$(gum choose \
        "1- Get user information" \
    )
fi

# PDF Actions Submenu
if [[ "$tooling" == *"PDF"* ]] ; then
    gum format -- "What do you to do with the PDF?"
    action=$(gum choose \
        "1- Convert pages to images" \
    )
fi

# Kubernetes Actions Submenu
if [[ "$tooling" == *"Kubernetes"* ]] ; then
    gum format -- "What do you to do with Kubernetes?"
    action=$(gum choose \
        "1- Get ports fowarded" \
    )
fi

# HTTP Actions Submenu
if [[ "$tooling" == *"HTTP"* ]] ; then
    gum format -- "What do you to do with HTTP?"
    action=$(gum choose \
        "1- Find if website is DDoS protected" \
    )
fi

# YouTube Actions Submenu
if [[ "$tooling" == *"YouTube"* ]] ; then
    gum format -- "What do you to do with YouTube?"
    action=$(gum choose \
        "1- Download a video thumbnail" \
    )
fi

###########
# Actions #
###########

#
# GitHub: get information about an user
#
if [[ "$tooling" == *"GitHub"* && "$action" == *"Get user information"* ]] ; then
    gum format -- "Which username?"
    local username=$(gum input --placeholder "fharper")

    echo ""
    curl -sS -H "Authorization: Bearer $GITHUB_TOKEN" "$github_api/users/$username" | jq '.name, .email, .blog' | tr -d '"' && curl -sS -H "Authorization: Bearer $GITHUB_TOKEN" "$github_api/users/$username/social_accounts" | jq '.[] .url' | tr -d '"'

#
# Kubernetes: get ports forwarded from a cluster
#
elif [[ "$tooling" == *"Kubernetes"* && "$action" == *"Get ports fowarded"* ]] ; then
    kubectl get svc -o json | jq '.items[] | {name:.metadata.name, p:.spec.ports[] } | select( .p.nodePort != null ) | "\(.name): localhost:\(.p.nodePort) -> \(.p.port) -> \(.p.targetPort)"'

#
# HTTP: find if website is DDoS protected
#
elif [[ "$tooling" == *"HTTP"* && "$action" == *"Find if website is DDoS protected"* ]] ; then
    gum format -- "Which site?"
    local site=$(gum input --placeholder "https://fred.dev")

    echo ""
    curl -sSI "$site" | grep -E 'cloudflare|Pantheon' || echo "Nope"

#
# PDF: convert pages to images
#
elif [[ "$tooling" == *"PDF"* && "$action" == *"Convert pages to images"* ]] ; then
    gum format -- "What file?"
    local file=$(gum input --placeholder "/Users/fharper/Downloads/be like batman.pdf")
    mkdir -p pdf-images

    echo ""
    local filename=$(basename "$file" .pdf)
    convert -density 300 "$file" -quality 100 "pdf-images/$filename.jpg"
    echo "images are in the pdf-images folder"

#
# YouTube: download a video thumbnail
#
elif [[ "$tooling" == *"YouTube"* && "$action" == *"Download a video thumbnail"* ]] ; then
    gum format -- "Which video?"
    local video=$(gum input --placeholder "https://www.youtube.com/watch?v=-8pX4ayi_XY")

    id=$(echo "$video" | sed 's/.*v=//g')
    curl "https://img.youtube.com/vi/$id/maxresdefault.jpg" > youtube_video_thumbnail.jpg

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
