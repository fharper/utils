#!/bin/zsh

################################################################################
#
# ZSH script with a bunch of command line utilities
#
# Making it easier to remind some difficult or commands I don't use often or
# easily do someting with multiple steps. Please use at your own risk!
#
################################################################################

##################
# Configurations #
##################
# https://github.com/short-pixel-optimizer/shortpixel-php
local shortpixel="/Users/fharper/Documents/code/others/shortpixel-php/"

# Used for input using the checkSudo function
# You can't output text to display in the Terminal while a subshell (with '$()') is waiting for the command output.
# It will display only in the end, which isn't useful in the while condition I'm using.
# See https://stackoverflow.com/a/64810239/895232
local sudo_needed=0

#############
# Constants #
#############
local github_api="https://api.github.com"
local videos_extensions=".mp4|.avi|.mov|.m4p|.m4v|.webm|.mpg|.mp2|.mpeg|.mpe|.mpv|.ogg|.wmv|.qt"
local images_extensions=".png|.jpeg|.jpg|.gif|.bmp|.tiff"
local YELLOW="\033[1;93m"
local RED="\033[0;31m"
local NOFORMAT="\033[0m"
local BOLD="\033[1m"
local ITALIC="\033[3m"

#############
# Functions #
#############

#
# Print something with style
#
# @param the message to display
#
function say {
    gum style --foreground 93 "$1"
}

#
# Install missing application (dependency for the selected feature from this script to run properly)
#
# @param the Homebrew formula name
# @param the website for the application
#
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
            print "Please install ${YELLOW}Homebrew${NOFORMAT} or ${YELLOW}$application${NOFORMAT} manually (see $website for instructions) and run the script again."
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

#
# Clear last terminal line
#
function clearLastLine {
    tput cuu 1 >&2
    tput el >&2
}

#
# Select a file from the running directory
#
# @param file type (Images, PDFs...)
# @param file extension (.pdf, .png, .jpg). If multiple extensions, use ".png|.jpeg"
#
# Return the file selected by the user
#
function getFile {
    local files=$(/bin/ls | egrep "$2")
    clearLastLine #I cannot get the error output to silence!
    local file;

    if [[ $files ]] ; then
        print "Please select a ${YELLOW}$1${NOFORMAT}" >&2
        file=$(/bin/ls  | sort -f | egrep "$2" | gum choose)
    else
        print "No $1 in this folder: you need to enter the ${YELLOW}full path of the $1${NOFORMAT} manually" >&2
        file=$(gum input --placeholder "/Users/fharper/Downloads/your-file$2")
    fi

    clearLastLine
    print "$file"
}

#
# Display an error message with red formatting
#
# @param the error message
#
function error {
    print "\n${RED}$1${NOFORMAT}\n"
}

#
# Check if PDF is protected
#
# @param PDF file to check
#
# Return the protection status
#
function isPdfProtected {
    local output=$(gs -dBATCH -sNODISPLAY "$1" 2>&1 | grep -o "This file requires a password")

    local protection="protected"
    if [[ ! $output ]] ; then
        protection="un$protection"
    fi

    print "$protection"
}

#
# Check if the user will have to enter the password when needing root access using sudo
#
# @param the reason why sudo is needed
#
# return 0 if not needed, 1 if it is
#
function checkSudo {
    sudo -n true 2>/dev/null
    sudo_needed=$(echo $?)

    if [[ $sudo_needed == 1 ]] ; then
        print
        gum format -- "sudo is require to $1"
        print
    fi
}

#
# Get the file name without the extension
#
# @param file
#
# return file name
#
function getFilename {
    echo "${1%.*}"
}

#
# Get the file extension
#
# @param file
#
# return file extension
#
function getFileExtension {
    echo "${1##*.}"
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
gum style --foreground 212 --border-foreground 212 --border double --align center --width 100 --margin "1 2" --padding "2 4" 'Utils' 'With great power comes great responsibility, use carefully!'

while [[ "$tooling" != *"EXIT"* ]] ; do

    #
    # Tooling menu
    #
    local action=""
    gum format -- "What tooling do you want to use utils for?"
    local tooling=$(gum choose --height=20 --cursor="" \
        "  ﹥ Any File" \
        "  ﹥ Any Image" \
        "  ﹥ Any Video" \
        "  ﹥ Apple" \
        "  ﹥ GitHub" \
        "  ﹥ HEIC" \
        "  ﹥ HTTP" \
        "  ﹥ Kubernetes" \
        "  ﹥ PDF" \
        "  ﹥ System" \
        "  ﹥ WAV" \
        "  ﹥ WEBP" \
        "  ﹥ YouTube" \
        "     EXIT" \
    )
    clearLastLine

    # Any Files Submenu
    if [[ "$tooling" == *"Any File"* ]] ; then
        gum format -- "What do you to do with the file?"
        action=$(gum choose --height=20 --cursor="" \
            "  ﹥ Get mime type" \
            "  ↵ Go back" \
        )

    # Any Images Submenu
    elif [[ "$tooling" == *"Any Image"* ]] ; then
        gum format -- "What do you to do with the image?"
        action=$(gum choose --height=20 --cursor="" \
            "  ﹥  Compress (lossless)" \
            "  ﹥  Convert to PDF" \
            "  ↵ Go back" \
        )

    # Any Videos Submenu
    elif [[ "$tooling" == *"Any Video"* ]] ; then
        gum format -- "What do you to do with the video?"
        action=$(gum choose --height=20 --cursor="" \
            "  ﹥  Check quality difference" \
            "  ﹥  Convert (lossless)" \
            "  ﹥  Extract audio" \
            "  ↵ Go back" \
        )

    # Apple Submenu
    elif [[ "$tooling" == *"Apple"* ]] ; then
        gum format -- "What do you to do with Apple?"
        action=$(gum choose --height=20 --cursor="" \
            "  > Download latest macOS" \
            "  > Show Time Machine logs" \
            "  ↵ Go back" \
        )

    # GitHub Actions Submenu
    elif [[ "$tooling" == *"GitHub"* ]] ; then
        gum format -- "What do you to do with GitHub?"
        action=$(gum choose --height=20 --cursor="" \
            "  > Get total of PR merged for an user in a repository" \
            "  > Get user information" \
            "  ↵ Go back" \
        )

    # HEIC Actions Submenu
    elif [[ "$tooling" == *"HEIC"* ]] ; then
        gum format -- "What do you to do with the HEIC file?"
        action=$(gum choose --height=20 --cursor="" \
            "  > Convert to JPG" \
            "  ↵ Go back" \
        )

    # HTTP Actions Submenu
    elif [[ "$tooling" == *"HTTP"* ]] ; then
        gum format -- "What do you to do with HTTP?"
        action=$(gum choose --height=20 --cursor="" \
            "  > Find if website is DDoS protected" \
            "  > Find website web server" \
            "  ↵ Go back" \
        )

    # Kubernetes Actions Submenu
    elif [[ "$tooling" == *"Kubernetes"* ]] ; then
        gum format -- "What do you to do with Kubernetes?"
        action=$(gum choose --height=20 --cursor="" \
            "  > Get all namespaces (CSV)" \
            "  > Get ports fowarded" \
            "  ↵ Go back" \
        )

    # PDF Actions Submenu
    elif [[ "$tooling" == *"PDF"* ]] ; then
        gum format -- "What do you to do with the PDF?"
        action=$(gum choose --height=20 --cursor="" \
            "  > Check if encrypted" \
            "  > Check if protected" \
            "  > Compress (lossless)" \
            "  > Convert pages to images" \
            "  > Convert to SVG" \
            "  > Crack protected" \
            "  > Decrypt" \
            "  > Extract embedded images" \
            "  > List embedded fonts" \
            "  > List embedded images" \
            "  > List number of pages" \
            "  > Merge two PDFs" \
            "  > Remove password protection" \
            "  ↵ Go back" \
        )

    # System Actions Submenu
    elif [[ "$tooling" == *"System"* ]] ; then
        gum format -- "What do you to do with the system?"
        action=$(gum choose --height=20 --cursor="" \
            "  > Clean disk space" \
            "  > Get information" \
            "  > Find port usage" \
            "  ↵ Go back" \
        )

    # WAV Actions Submenu
    elif [[ "$tooling" == *"WAV"* ]] ; then
        gum format -- "What do you to do with the WAV file?"
        action=$(gum choose --height=20 --cursor="" \
            "  > Convert to MP3" \
            "  ↵ Go back" \
        )

    # WEBP Actions Submenu
    elif [[ "$tooling" == *"WEBP"* ]] ; then
        gum format -- "What do you to do with the WEBP file?"
        action=$(gum choose --height=20 --cursor="" \
            "  > Convert to JPG" \
            "  ↵ Go back" \
        )

    # YouTube Actions Submenu
    elif [[ "$tooling" == *"YouTube"* ]] ; then
        gum format -- "What do you to do with YouTube?"
        action=$(gum choose --height=20 --cursor="" \
            "  > Download a video thumbnail" \
            "  ↵ Go back" \
        )

    # If empty, Ctrl + C was selected (for whatever reason I cannot trap SIGINT)
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

            print "\nThe mime type is ${YELLOW}$type${NOFORMAT}\n"
        else
            error "No file selected."
        fi

    #
    # Any Image
    #
    elif [[ "$tooling" == *"Any Image"* ]] ; then

        #
        # Compress (lossless)
        #
        if [[ "$action" == *"Compress (lossless)"* ]] ; then

            if [[ $(which php | grep "not found" ) ]] ; then
                installApp "php" "https://github.com/php/php-src"
            elif [[ -z "${SHORTPIXEL_API}" ]] ; then
                print "Please set the SHORTPIXEL_API environment variable with your ShortPixel API Key."
            else
                local file=$(getFile "file" "$images_extensions")

                if [[ $file ]] ; then
                    local filename=$(getFilename "$file")
                    local extension=$(getFileExtension "$file")

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
                    error "No file selected."
                fi
            fi

        #
        # Compress (lossless)
        #
        elif [[ "$action" == *"Convert to PDF"* ]] ; then
            if [[ $(which convert | grep "not found" ) ]] ; then
                installApp "ImageMagick" "https://github.com/ImageMagick/ImageMagick"
            else
                local file=$(getFile "file" "$images_extensions")

                if [[ $file ]] ; then
                    local filename=$(getFilename "$file")
                    local pdf="$filename.pdf";
                    print
                    gum spin --spinner line --title "Converting the image to PDF..." -- convert "$file" "$pdf"
                    echo "Converted image: ${YELLOW}$pdf${NOFORMAT}\n"
                else
                    error "No file selected."
                fi
            fi
        fi

    #
    # Any Video
    #
    elif [[ "$tooling" == *"Any Video"* ]] ; then

        #
        # Check quality difference
        #
        if [[ "$action" == *"Check quality difference"* ]] ; then

            # ffprobe is also installed with ffmpeg
            if [[ $(which ffmpeg | grep "not found" ) ]] ; then
                installApp "ffmpeg" "https://github.com/FFmpeg/FFmpeg"
            else
                local firstFile=$(getFile "first video" "$videos_extensions")

                if [[ "$firstFile" ]] ; then
                    local secondFile=$(getFile "second video" "$videos_extensions")

                    if [[ "$secondFile" ]] ; then
                        ffmpeg -i "$firstFile" -i "$secondFile" -filter_complex "blend=all_mode=difference" -c:v libx264 -crf 18 -c:a copy video-difference.mp4

                        local confirmation=$(gum confirm "The differences are highlighted in video-difference.mp4 (green = same). Want to watch the result?" && print "true" || print "false")
                        if [[ $confirmation == "true" ]] ; then
                            open video-difference.mp4
                        fi
                    else
                        error "No file selected."
                    fi
                else
                    error "No file selected."
                fi
            fi

        #
        # Convert (lossless)
        #
        elif [[ "$action" == *"Convert (lossless)"* ]] ; then
                if [[ $(which ffmpeg | grep "not found" ) ]] ; then
                installApp "ffmpeg" "https://github.com/FFmpeg/FFmpeg"
            else
                local file=$(getFile "first video" "$videos_extensions")

                if [[ "$file" ]] ; then

                    local extensions=($(echo "$videos_extensions" | sed 's/\./\"/g' | sed 's/|/\" /g')\")

                    local command="gum choose --height=20 --cursor=\"\""
                    for which in "$extensions[@]"; do
                        command="$command $which"
                    done

                    gum format -- "Which video format output?"
                    local format=$(eval "$command")
                    clearLastLine

                    if [[ "$format" ]] ; then
                        local filename=$(getFilename "$file")

                        print
                        ffmpeg -loglevel error -stats -i "$file" -crf 18 -preset veryslow -c:a copy "$filename-output.$format"
                        print
                    else
                        error "No file format selected."
                    fi
                else
                    error "No file selected."
                fi
            fi

        #
        # Extract audio
        #
        elif [[ "$action" == *"Extract audio"* ]] ; then
                if [[ $(which ffmpeg | grep "not found" ) ]] ; then
                installApp "ffmpeg" "https://github.com/FFmpeg/FFmpeg"
            else
                local file=$(getFile "video" "$videos_extensions")

                if [[ "$file" ]] ; then
                    local filename=$(getFilename "$file")
                    local audioFile="$filename.wav"
                    ffmpeg -i "$file" "$audioFile"

                    print "\nExtracted audio: ${YELLOW}$audioFile${NOFORMAT}\n"
                fi
            fi

        fi

    #
    # Apple
    #
    elif [[ "$tooling" == *"Apple"* ]] ; then

        #
        # Download latest macOS
        #
        if [[ "$action" == *"Download latest macOS"* ]] ; then
            if [[ $(which curl | grep "not found" ) ]] ; then
                installApp "curl" "https://github.com/curl/curl"
            else
                local url=$(curl -s https://mesu.apple.com/assets/macos/com_apple_macOSIPSW/com_apple_macOSIPSW.xml | grep ipsw | tail -1 | sed -r 's/\t+<string>//g' | sed 's/<\/string>//g')
                local file=$(print $url | sed -E 's/^.*\/(.*ipsw)/\1/g')
                local version=$(print $file | sed -E 's/.*_(.*)_.*_.*/\1/g')
                print "Downloading macOS version $version\n"
                curl "$url" -o "$file"
            fi

        #
        # Show Time Machine logs
        #
        elif [[ "$action" == *"Show Time Machine logs"* ]] ; then
            gum format -- "Get the Time Machine logs for the last..."
            local last=$(gum choose --height=20 --cursor="" \
                "  ﹥ 5 minutes" \
                "  ﹥ 1 hour" \
                "  ﹥ 1 day" \
                "  ﹥ 1 week" \
            )
            clearLastLine

            if [[ $last ]] ; then
                last=$(print $last | sed 's/  ﹥ //g' | sed 's/ minutes/m/g' | sed 's/ hour/h/g' | sed 's/ day/d/g' | sed 's/1 week/7d/g')
                /usr/bin/log show --info --style compact --predicate 'subsystem == "com.apple.TimeMachine"' --last $last --color always | more -r
                print
            else
                error "No time span selected."
            fi
        fi

    #
    # GitHub
    #
    elif [[ "$tooling" == *"GitHub"* ]] ; then

        #
        # Get total of PR merged for an user in a repository
        #
        if [[ "$action" == *"Get total of PR merged for an user in a repository"* ]] ; then
            if [[ $(which curl | grep "not found" ) ]] ; then
                installApp "curl" "https://github.com/curl/curl"
            elif [[ $(which jq | grep "not found" ) ]] ; then
                    installApp "jq" "https://github.com/jqlang/jq"
            else
                gum format -- "Which username?"
                local username=$(gum input --placeholder "fharper")
                clearLastLine

                if [[ $username ]] ; then

                    gum format -- "Which repository?"
                    local repository=$(gum input --placeholder "fharper/coffeechat")
                    clearLastLine

                    if [[ $repository ]] ; then

                        gum format -- "Starting on which date (YYYY-MM-DD)?"
                        local date_from=$(gum input --placeholder "2023-10-01")
                        clearLastLine

                        if [[ $date_from ]] ; then

                            gum format -- "Ending on which date (YYYY-MM-DD)?"
                            local date_to=$(gum input --placeholder "2023-12-31")
                            clearLastLine

                            if [[ $date_to ]] ; then

                                total_pr=$(gum spin --show-output --spinner line --title "Getting total number of PR..." -- curl -s "https://api.github.com/search/issues?q=repo:$repository%20author:$username%20is:pr%20is:merged%20merged:$date_from..$date_to" | jq '.total_count')

                                print "Number of PR for ${YELLOW}$username${NOFORMAT} on ${YELLOW}$repository${NOFORMAT} between ${YELLOW}$date_from${NOFORMAT} and ${YELLOW}$date_to${NOFORMAT} is ${YELLOW}$total_pr${NOFORMAT}\n"
                            else
                                error "No from date was entered."
                            fi
                        else
                            error "No from date was entered."
                        fi
                    else
                        error "No repository was entered."
                    fi
                else
                    error "No username was entered."
                fi
            fi

        #
        # Get user information
        #
        elif [[ "$action" == *"Get user information"* ]] ; then
            if [[ $(which curl | grep "not found" ) ]] ; then
                installApp "curl" "https://github.com/curl/curl"
            elif [[ $(which jq | grep "not found" ) ]] ; then
                    installApp "jq" "https://github.com/jqlang/jq"
            else
                gum format -- "Which username?"
                local username=$(gum input --placeholder "fharper")
                clearLastLine

                if [[ $username ]] ; then
                    print ""
                    curl -sS -H "Authorization: Bearer $GITHUB_TOKEN" "$github_api/users/$username" | jq -r '.name, .email, .blog' && curl -sS -H "Authorization: Bearer $GITHUB_TOKEN" "$github_api/users/$username/social_accounts" | jq -r '.[] .url'
                    print ""
                else
                    error "No username was entered."
                fi
            fi
        fi

    #
    # HEIC: Convert to JPG
    #
    elif [[ "$tooling" == *"HEIC"* && "$action" == *"Convert to JPG"* ]] ; then

        if [[ $(which convert | grep "not found" ) ]] ; then
            installApp "ImageMagick" "https://github.com/ImageMagick/ImageMagick"
        else
            print
            local file=$(getFile "HEIC" ".heic")

            if [[ $file ]] ; then
                local jpg=${file/%heic/jpg}

                print
                gum spin --spinner line --title "Converting the HEIC image to JPG..." -- convert "$file" "$jpg"
                print "\n ${YELLOW}$file${NOFORMAT} was converted to ${YELLOW}$jpg${NOFORMAT}\n"
            else
                error "No file selected."
            fi
        fi

    #
    # HTTP
    #
    elif [[ "$tooling" == *"HTTP"* ]] ; then

        #
        # Find if website is DDoS protected
        #
        if [[ "$action" == *"Find if website is DDoS protected"* ]] ; then
            if [[ $(which curl | grep "not found" ) ]] ; then
                installApp "curl" "https://github.com/curl/curl"
            else
                gum format -- "Which site?"
                local site=$(gum input --placeholder "https://fred.dev")
                clearLastLine

                if [[ $site ]] ; then
                    print ""
                    curl -sSI "$site" | grep -E 'cloudflare|Pantheon|heroku' || print "Nope"
                    print ""
                else
                    error "No site was entered.\n"
                fi
            fi

        #
        # Find website web server
        #
        elif [[ "$action" == *"Find website web server"* ]] ; then
            if [[ $(which curl | grep "not found" ) ]] ; then
                installApp "curl" "https://github.com/curl/curl"
            else
                gum format -- "Which site?"
                local site=$(gum input --placeholder "https://fred.dev")
                clearLastLine

                if [[ $site ]] ; then
                    print ""
                    curl -sSI "$site" | sed -n 's/^S[erv]*: //p'
                    print ""
                else
                    error "No site was entered.\n"
                fi
            fi
        fi

    #
    # Kubernetes
    #
    elif [[ "$tooling" == *"Kubernetes"* ]] ; then

        #
        # get ports forwarded from a cluster
        #
        if [[ "$action" == *"Get ports fowarded"* ]] ; then

            if [[ $(which kubectl | grep "not found" ) ]] ; then
                installApp "kubectl" "https://github.com/kubernetes/kubectl"
            else
                local result=$(kubectl get svc -o json | jq '.items[] | {name:.metadata.name, p:.spec.ports[] } | select( .p.nodePort != null ) | "\(.name): localhost:\(.p.nodePort) -> \(.p.port) -> \(.p.targetPort)"')

                if [[ ! "$result" ]] ; then
                    error "No ports are forwarded.\n"
                fi
            fi

        #
        # Get all namespaces (CSV)
        #
        elif [[ "$action" == *"Get all namespaces (CSV)"* ]] ; then

            if [[ $(which kubectl | grep "not found" ) ]] ; then
                installApp "kubectl" "https://github.com/kubernetes/kubectl"
            elif [[ $(which jq | grep "not found" ) ]] ; then
                installApp "jq" "https://github.com/jqlang/jq"
            else
                kubectl get namespaces --output='json' | jq '.items.[].metadata.name' | tr '\n' ',' | tr -d "\"" | sed 's/.$//'
                print
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
                print "Do you want them with a white background?"
                local background=$(gum choose --height=20 --cursor="" --selected="Yes" \
                    "  Yes" \
                    "  No" \
                )
                clearLastLine

                print ""
                local file=$(getFile "PDF" ".pdf")

                if [[ $file ]] ; then
                    print ""
                    local filename=$(basename "$file" .pdf)
                    mkdir -p pdf-images

                    if [[ $background == *"Yes"* ]] ; then
                        background=" -background white -alpha remove -alpha off"
                    else
                        background=""
                    fi

                   gum spin --spinner line --title "Converting the PDF pages into images..." -- convert -density 300 -quality 100 "$background" "$file" "pdf-images/$filename.jpg"

                    print "The images of the pages from ${YELLOW}$file${NOFORMAT} are in the ${YELLOW}pdf-images${NOFORMAT} folder\n"
                else
                    error "No file selected."
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
                    filename="$filename-compressed.pdf"

                    gum spin --spinner line --title "Compressing the PDF..." -- gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dCompatibilityLevel=1.7 -dNOPAUSE -dQUIET -dPDFSETTINGS=/prepress -sOutputFile="$filename"  "$file"

                    print "Compressed PDF: ${YELLOW}$filename${NOFORMAT}\n"
                else
                    error "No file selected."
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
                    error "No file selected."
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
                print "The number of pages is ${YELLOW}$pages${NOFORMAT}\n"
            else
                error "No file selected."
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

                    print "The file is ${YELLOW}$protection${NOFORMAT}\n"
                else
                    error "No file selected."
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
                    error "No file selected."
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
                    error "No file selected."
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

                        print "The file is ${YELLOW}encrypted${NOFORMAT} with the ${YELLOW}$algorithm${NOFORMAT} algorithm:"

                        local print=$(print $output | egrep -o 'print:\S*' | sed -n "s/print:/$1/p")
                        print "Printing: ${YELLOW}$print${NOFORMAT}"

                        local copy=$(print $output | egrep -o 'copy:\S*' | sed -n "s/copy:/$1/p")
                        print "Copying: ${YELLOW}$copy${NOFORMAT}"

                        local change=$(print $output | egrep -o 'change:\S*' | sed -n "s/change:/$1/p")
                        print "Changing: ${YELLOW}$change${NOFORMAT}"

                        local notes=$(print $output | egrep -o 'addNotes:\S*' | sed -n "s/addNotes:/$1/p")
                        print "Add Notes: ${YELLOW}$notes${NOFORMAT}"
                    else
                        print "The file is ${YELLOW}not encrypted${NOFORMAT}"
                    fi

                    print ""
                else
                    error "No file selected."
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
                        print "File ${YELLOW}$unlocked_file${NOFORMAT} unlocked/decrypted"
                        print ""
                    fi
                else
                    error "No file selected."
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
                        error "No file selected."
                    fi
                fi
            fi

        #
        # Remove password protection
        #
        elif [[ "$action" == *"Remove password protection"* ]] ; then

            if [[ $(which qpdf | grep "not found" ) ]] ; then
                installApp "qpdf" "https://github.com/qpdf/qpdf"
            else
                local file=$(getFile "PDF" ".pdf")
                local filename=$(basename "$file" .pdf)
                local unprotected_file="$filename-unprotected.pdf"

                if [[ $file ]] ; then

                    gum format -- "What is the password?"
                    local password=$(gum input --password)
                    clearLastLine

                    if [[ $password ]] ; then
                        print ""
                        qpdf --decrypt --password="$password" "$file" "$unprotected_file"
                        print "The unprotected PDF file is ${YELLOW}$unprotected_file${NOFORMAT}\n"
                    else
                        error "No password entered. If you lost your password, use the ${YELLOW}Crack protected${NOFORMAT} feature."
                    fi
                else
                    error "No file selected."
                fi
            fi

        #
        # Convert to SVG
        #
        elif [[ "$action" == *"Convert to SVG"* ]] ; then

            if [[ $(which pdf2svg | grep "not found" ) ]] ; then
                installApp "pdf2svg" "https://github.com/dawbarton/pdf2svg/"
            else
                local file=$(getFile "PDF" ".pdf")
                local filename=$(basename "$file" .pdf)
                local svg="$filename.svg"

                if [[ $file ]] ; then
                    echo
                    gum spin --spinner line --title "Converting the PDF into a SVG file..." --  pdf2svg "$file" "$svg"

                    print "The file ${YELLOW}$file${NOFORMAT} has been converted to ${YELLOW}$svg${NOFORMAT}\n"
                fi
            fi

        #
        # Merge two PDFs
        #
        elif [[ "$action" == *"Merge two PDFs"* ]] ; then

            if [[ $(which pdfunite | grep "not found" ) ]] ; then
                installApp "Poppler" "https://poppler.freedesktop.org"
            else
                local file1=$(getFile "first PDF" ".pdf")

                if [[ $file1 ]] ; then

                    local file2=$(getFile "second PDF" ".pdf")

                    if [[ $file2 ]] ; then
                        pdfunite "$file1" "$file2" merged.pdf
                        print "The files ${YELLOW}$file1${NOFORMAT} and ${YELLOW}$file2${NOFORMAT} has been merged to ${YELLOW}merged.pdf${NOFORMAT}\n"
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
                error "No file selected."
            fi
        fi

    #
    # WEBP: Convert to JPG
    #
    elif [[ "$tooling" == *"WEBP"* && "$action" == *"Convert to JPG"* ]] ; then

        if [[ $(which convert | grep "not found" ) ]] ; then
            installApp "ImageMagick" "https://github.com/ImageMagick/ImageMagick"
        else
            print ""
            local file=$(getFile "WEBP" ".webp")

            if [[ $file ]] ; then
                local jpg="${file/%webp/jpg}"

                print ""
                convert "$file" "$jpg";
                print "${YELLOW}$file${NOFORMAT} converted to ${YELLOW}$jpg${NOFORMAT}\n"
            else
                error "No file selected."
            fi
        fi

    #
    # System
    #
    elif [[ "$tooling" == *"System"* ]] ; then

        #
        # System: Get information
        #
        if [[ "$action" == *"Get information"* ]] ; then
            if [[ $(which jq | grep "not found" ) ]] ; then
                installApp "jq" "https://github.com/jqlang/jq"

            elif [[ $(which cws | grep "not found" ) ]] ; then
                installApp "cws" "https://github.com/vladimyr/chrome-webstore-cli"

            else
                local info=("OS" "Browsers" "Internet Connection")
                local infoUnselected=("Displays" "Terminal & Shell" "SDKs" "Docker" "Clouds CLIs" "IDEs" "Visual Studio Extensions" "External IP Address")

                local command="gum choose"

                #Listing the choices
                for what in "$info[@]"; do
                    command="$command \"$what\""
                done

                #Listing the unselected by default choices
                for what in "$infoUnselected[@]"; do
                    command="$command \"$what\""
                done

                command="$command --no-limit"

                #Selecting all the choices
                for what in "$info[@]"; do
                    command="$command  --height=20 --selected=\"$what\""
                done

                gum format -- "What information about your system do you need?"
                local selectedInfo=("${(@f)$(eval $command)}")
                clearLastLine

                print "\nLoading the system information, please wait..."
                local data=""
                local steps=${#selectedInfo[@]}
                local step=1

                #Operating System
                if [[ ${selectedInfo[(ie)OS]} -le ${#selectedInfo} ]] ; then
                    print "Loading the ${YELLOW}operating system${NOFORMAT} information [$step/$steps]"
                    ((step++))

                    codename=$(sed -nE '/SOFTWARE LICENSE AGREEMENT FOR/s/.*([A-Za-z]+ ){5}|\\$//gp' /System/Library/CoreServices/Setup\ Assistant.app/Contents/Resources/en.lproj/OSXSoftwareLicense.rtf)

                    data="${data}${YELLOW}------------------\n"
                    data="${data} Operating System \n"
                    data="${data}------------------${NOFORMAT}\n"
                    data="${data}$(sw_vers -productName) ($codename) $(sw_vers -productVersion) build $(sw_vers -buildVersion) on $(/usr/bin/arch)\n\n"
                fi

                #Internet Connection
                if [[ ${selectedInfo[(ie)Internet Connection]} -le ${#selectedInfo} ]] ; then
                    print "Loading the ${YELLOW}internet connection${NOFORMAT} information [$step/$steps]"
                    ((step++))

                    if [[ $(which speedtest-cli | grep "not found" ) ]] ; then
                        installApp "speedtest-cli" "https://github.com/sivel/speedtest-cli"
                    else
                        data="${data}${YELLOW}---------------------\n"
                        data="${data} Internet Connection \n"
                        data="${data}---------------------${NOFORMAT}\n"

                        # Speed
                        data="${data}$(speedtest-cli --secure --simple)\n"

                        # Signal Strength
                        local signal_sum=0
                        local i=0
                        while [[ $i -lt 50 ]] ; do
                            ((signal_sum+=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | grep CtlRSSI | sed -e 's/^.*: //g')))
                            sleep 0.5
                            ((i++))
                        done
                        data="${data}Signal Strength: $((signal_sum/i)) \n"

                        # Packet loss
                        data="${data}Packet loss: $(ping -q -c 50 1.1.1.1 | grep 'packet loss' | sed 's/.*received, \(.*\) packet loss/\1/' | sed 's/^0.0%/None/')\n\n"
                    fi
                fi

                #Browsers
                if [[ ${selectedInfo[(ie)Browsers]} -le ${#selectedInfo} ]] ; then
                    print "Loading the ${YELLOW}browser(s)${NOFORMAT} information [$step/$steps]"
                    ((step++))

                    data="${data}${YELLOW}----------\n"
                    data="${data} Browsers \n"
                    data="${data}----------${NOFORMAT}\n"

                    # Brave
                    if [[ -d "/Applications/Brave Browser.app" ]] ; then
                        data="${data}$(/Applications/Brave\ Browser.app/Contents/MacOS/Brave\ Browser --version)\n"
                    fi

                    # Chromium
                    if [[ -d "/Applications/Chromium.app" ]] ; then
                        data="${data}$(/Applications/Chromium.app/Contents/MacOS/Chromium --version)\n"
                    fi

                    # Google Chrome
                    if [[ -d "/Applications/Google Chrome.app" ]] ; then
                        SAVEIFS=$IFS
                        IFS=$'\n'

                        data="${data}$(/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version)\n"

                        # Extensions
                        data="${data}  Extensions:"
                        extensions_manifests=($(fd manifest.json ~/Library/Application\ Support/Google/Chrome/Profile\ 1/Extensions/))

                        local extensions=""
                        for file in "$extensions_manifests[@]"; do
                            local id=$(echo $file | sed 's/.*Extensions\/\(.*\)\/.*\/manifest.json/\1/')

                            local name=""

                            # https://www.reddit.com/r/chrome/comments/w9xpzb/comment/ihyc54i/
                            if [[ "$id" == "nmmhkkegccagdldgiimedpiccmgmieda" ]] ; then
                                name="Google Wallet" # Hidden Chrome extension
                            else
                                name=$(jq -r '.short_name' "$file")

                                # Some don't have short_name in the manifest
                                if [[ "$name" == "null" || "$name" == *"__MSG"* ]] ; then
                                    name=$(jq -r '.name' "$file")

                                    # Some don't have name either
                                    if [[ "$name" == "null" || "$name" == *"__MSG"* ]] ; then
                                        name=$(cws info "$id" --json | jq -r '.name')
                                    fi
                                fi
                            fi

                            local version=$(echo $file | sed 's/.*Extensions\/.*\/\(.*\)_0\/manifest.json/\1/')
                            extensions="${extensions}    $name $version\n"
                        done

                        extensions=$(echo $extensions | sort -f)
                        data="${data}  $extensions\n"

                        IFS=$SAVEIFS
                    fi

                    # Microsoft Edge
                    if [[ -d "/Applications/Microsoft Edge.app" ]] ; then
                        data="${data}$(/Applications/Microsoft\ Edge.app/Contents/MacOS/Microsoft\ Edge --version)\n"
                    fi

                    # Mozilla Firefox
                    if [[ -d "/Applications/Firefox.app" ]] ; then
                        data="${data}$(/Applications/Firefox.app/Contents/MacOS/Firefox --version)\n"

                        # Extensions
                        data="${data}  Extensions:"
                        local extensions=$(cat ~/Library/Application\ Support/Firefox/Profiles/*.default*/addons.json | jq -r '.addons[]' | jq  -r '["   ", .name, .version] | @sh' | tr -d "'")
                        data="${data}\n$extensions\n"
                    fi

                    # Opera
                    if [[ -d "/Applications/Opera.app" ]] ; then
                        data="${data}Opera $(/Applications/Opera.app/Contents/MacOS/Opera --version)\n"
                    fi

                    # Opera GX
                    if [[ -d "/Applications/Opera GX.app" ]] ; then
                        data="${data}Opera GX $(/Applications/Opera\ GX.app/Contents/MacOS/Opera --version)\n"
                    fi

                    # Safari
                    if [[ -d "/Applications/Safari.app" ]] ; then
                        data="${data}Safari $(/usr/libexec/PlistBuddy -c "print :CFBundleShortVersionString" /Applications/Safari.app/Contents/Info.plist) ($(/usr/libexec/PlistBuddy -c "print :CFBundleVersion" /Applications/Safari.app/Contents/Info.plist))\n"
                    fi

                    data="${data}\n"
                fi

                #Display(s)
                if [[ ${selectedInfo[(ie)Displays]} -le ${#selectedInfo} ]] ; then
                    print "Loading the ${YELLOW}display(s)${NOFORMAT} information [$step/$steps]"
                    ((step++))

                    data="${data}${YELLOW}----------\n"
                    data="${data} Displays \n"
                    data="${data}----------${NOFORMAT}\n"
                    local resolutions=$(system_profiler SPDisplaysDataType | grep Resolution)
                    data="${data}${resolutions:gs/          /}\n\n"
                fi

                #Terminal & Shell
                if [[ ${selectedInfo[(ie)Terminal & Shell]} -le ${#selectedInfo} ]] ; then
                    print "Loading the ${YELLOW}terminal & shell${NOFORMAT} information [$step/$steps]"
                    ((step++))

                    data="${data}${YELLOW}------------------\n"
                    data="${data} Terminal & Shell \n"
                    data="${data}------------------${NOFORMAT}\n"

                    if [[ -d "/Applications/iTerm.app" ]] ; then
                        data="${data}iTerm2: $(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" /Applications/iTerm.app/Contents/Info.plist)\n"
                    fi

                    # Check if sudo is needed
                    checkSudo "retrieve Shell informations"

                    local shell=$(sudo lsof -nP -p "$(ps -p "$$" -o ppid=)" | awk 'NR==3 {print $NF; exit}' | sed 's/.*\/\([^/]*\)$/\1/');

                    # Clearing the sudo prompt
                    if [[ "$sudo_needed" == 1 ]] ; then
                        clearLastLine
                        clearLastLine
                        clearLastLine
                    fi

                    data="${data}Shell: $shell"

                    if [[ "$shell" == "zsh" ]] ; then
                        data="${data}$(zsh --version | sed 's/zsh \(.*\) (.*/\1/')\n"
                        source ~/.zshrc
                        data="${data}Oh My Zsh: $(omz version)"
                    fi

                    data="${data}\n\n"
                fi

                #SDKs
                if [[ ${selectedInfo[(ie)SDKs]} -le ${#selectedInfo} ]] ; then
                    print "Loading the ${YELLOW}SDK(s)${NOFORMAT} information [$step/$steps]"
                    ((step++))

                    data="${data}${YELLOW}------\n"
                    data="${data} SDKs \n"
                    data="${data}------${NOFORMAT}\n"

                    #.NET Core
                    data="${data}.NET Core $(dotnet --version)\n\n"

                    #Deno
                    data="${data}Deno $(deno --version | head -n 1 | sed -E 's/deno (.*) \(.*/\1/g')\n\n"

                    #Go
                    data="${data}Go $(go version | sed -E 's/go version go(.*) .*/\1/g')\n\n"

                    #Java
                    data="${data}Java $(java -version 2>&1 | head -n 1 | sed -E 's/openjdk version \"(.*)\".*/\1/g')\n\n"

                    #Node.js
                    local node_version=$(node --version)
                    local node_version_length=${#node_version}
                    data="${data}Node.js ${node_version[2,node_version_length]} with npm $(npm --version)\n\n"

                    #Perl
                    data="${data}Perl $(perl --version | sed '2!d' | sed -E 's/.*\(v(.*)\).*/\1/g')\n\n"

                    #PHP
                    data="${data}$(php --version | head -n 1 | sed -E 's/ \(cli\).*//g') with Composer $(composer --version | sed -E 's/Composer version (.*) [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{1,}/\1/g')\n\n"

                    #Python
                    data="${data}$(python --version) with $(pip --version | sed 's/\(.*\) from.*/\1/')\n\n"

                    #Ruby
                    data="${data}Ruby $(ruby --version | sed -E 's/ruby (.*) \(.*/\1/g') with gem $(gem --version| sed -E 's/gem/Gem/g')\n\n"

                    #Rust
                    data="${data}Rust $(rustc --version | sed -E 's/rustc (.*) \(.*/\1/g') with Cargo $(cargo --version | sed -E 's/cargo (.*) \(.*/\1/g')\n\n"
                fi

                #Docker
                if [[ ${selectedInfo[(ie)Docker]} -le ${#selectedInfo} ]] ; then
                    print "Loading the ${YELLOW}Docker${NOFORMAT} information [$step/$steps]"
                    ((step++))

                    data="${data}${YELLOW}--------\n"
                    data="${data} Docker \n"
                    data="${data}--------${NOFORMAT}\n"

                    if [[ $(docker version 2>&1 | grep "Cannot connect to the Docker daemon") ]] ; then
                        data="${data}Docker Desktop isn't running: start the app to get this information.\n\n"
                    else
                        data="${data}$(docker version | grep "Docker Desktop" | sed -E 's/Server: //g')\n\n"
                    fi
                fi

                #Clouds CLIs
                if [[ ${selectedInfo[(ie)Clouds CLIs]} -le ${#selectedInfo} ]] ; then
                    print "Loading the ${YELLOW}cloud CLI(s)${NOFORMAT} information [$step/$steps]"
                    ((step++))

                    data="${data}${YELLOW}-------------\n"
                    data="${data} Clouds CLIs \n"
                    data="${data}-------------${NOFORMAT}\n"

                    #AWS
                    data="${data}AWS $(aws --version | sed -E 's/aws-cli\/(.*) Python.*/\1/g')\n"

                    #Azure
                    data="${data}Azure $(az version | jq '."azure-cli"' | sed -E 's/"//g')\n"

                    #Civo
                    data="${data}$(civo --version | grep "Civo CLI" | sed -E 's/CLI v//g')\n"

                    #DigitalOcean
                    data="${data}DigitalOcean $(doctl version | sed -E 's/doctl version (.*)-release/\1/g')\n"

                    #Google
                    data="${data}$(gcloud --version | head -n 1 | sed -E 's/ SDK//g')\n"

                    #Vultr
                    data="${data}$(vultr-cli version | sed -E 's/-cli v/ /g')\n\n"
                fi

                #IDEs
                if [[ ${selectedInfo[(ie)IDEs]} -le ${#selectedInfo} ]] ; then
                    print "Loading the ${YELLOW}IDE(s)${NOFORMAT} information [$step/$steps]"
                    ((step++))

                    data="${data}${YELLOW}------\n"
                    data="${data} IDEs \n"
                    data="${data}------${NOFORMAT}\n"

                    #VIM
                    data="${data}VIM $(vi --version | head -n 1 | sed -E 's/VIM - Vi IMproved (.*) \(.*/\1/g')\n"

                    #Visual Studio Code
                    data="${data}Visual Studio Code $(code --version | head -n 1)\n\n"
                fi

                #Visual Studio Extensions
                if [[ ${selectedInfo[(ie)Visual Studio Extensions]} -le ${#selectedInfo} ]] ; then
                    print "Loading the ${YELLOW}Visual Studio extension(s)${NOFORMAT} information [$step/$steps]"
                    ((step++))

                    data="${data}${YELLOW}-------------------------------\n"
                    data="${data} Visual Studio Code Extensions \n"
                    data="${data}-------------------------------${NOFORMAT}\n"

                    data="${data}$(code --list-extensions --show-versions)"
                fi

                #External IP Address
                if [[ ${selectedInfo[(ie)External IP Address]} -le ${#selectedInfo} ]] ; then
                    print "Getting the ${YELLOW}external IP address${NOFORMAT}[$step/$steps]"
                    ((step++))

                    data="${data}${YELLOW}---------------------\n"
                    data="${data} External IP Address \n"
                    data="${data}---------------------${NOFORMAT}\n"

                    data="${data}$(curl https://ipinfo.io/ip)"
                fi

                # Display the system information
                clearLastLine
                while [[ $step -ne 0 ]] ; do
                    clearLastLine
                    ((step--))
                done
                print "\n$data"
                print "\n${ITALIC}it was copied to your clipboard${NOFORMAT}\n"

                #Removing formating before sending to clipboard
                data=${data//${YELLOW}/}
                data=${data//${NOFORMAT}/}

                # Copy it to clipboard
                print -- "$data" | pbcopy
            fi

        #
        # System: Find port usage
        #
        elif [[ "$action" == *"Find port usage"* ]] ; then

            if [[ $(which lsof | grep "not found" ) ]] ; then
                installApp "lsof" "https://github.com/lsof-org/lsof"
            else
                gum format -- "Which port?"
                local port=$(gum input --placeholder "8080")

                if [[ $port ]] ; then
                    clearLastLine

                    # Check if sudo is needed
                    checkSudo "prevent some file access errors"
                    local port_usage=$(sudo lsof -i tcp:"$port")

                    # Clearing the sudo prompt
                    if [[ $sudo_needed == 1 ]] ; then
                        clearLastLine
                        clearLastLine
                        clearLastLine
                    fi

                    # If not in use, still show a message
                    if [[ -z "$port_usage" ]] ; then
                        port_usage="No application is using port $port"
                    fi

                    print "\n$port_usage\n"
                fi
            fi

        #
        # System: Clean disk space
        #
        elif [[ "$action" == *"Clean disk space"* ]] ; then

            # Cleaning Hombrew cache
            if [[ $(which brew | grep -v "not found") ]] ; then
                local confirmation=$(gum confirm "Deleting Homebrew cache, are you sure?" && print "true" || print "false")

                if [[ $confirmation == "true" ]] ; then
                    rm -rf $(brew --cache)
                    say "Homebrew cache deleted"
                fi
            fi

            # Cleaning npm cache
            if [[ $(which npm | grep -v "not found") ]] ; then
                local confirmation=$(gum confirm "Deleting npm cache, are you sure?" && print "true" || print "false")

                if [[ $confirmation == "true" ]] ; then
                    npm cache clean --force
                    clearLastLine
                    say "npm cache deleted"
                fi
            fi

            # Cleaning yarn cache
            if [[ $(which yarn | grep -v "not found") ]] ; then
                local confirmation=$(gum confirm "Deleting yarn cache, are you sure?" && print "true" || print "false")

                if [[ $confirmation == "true" ]] ; then
                    yarn cache clean
                    say "yarn cache deleted"
                fi
            fi

            # Cleaning go cache
            if [[ $(which go | grep -v "not found") ]] ; then
                local confirmation=$(gum confirm "Deleting go cache, are you sure?" && print "true" || print "false")

                if [[ $confirmation == "true" ]] ; then
                    go clean -cache
                    say "go cache deleted"
                fi
            fi

            print
        fi

    #
    # YouTube: download a video thumbnail
    #
    elif [[ "$tooling" == *"YouTube"* && "$action" == *"Download a video thumbnail"* ]] ; then
        gum format -- "Which video?"
        local video=$(gum input --placeholder "https://www.youtube.com/watch?v=-8pX4ayi_XY")

        if [[ $video ]] ; then
            clearLastLine
            local id=$(print "$video" | sed 's/.*v=//g')
            curl -s "https://img.youtube.com/vi/$id/maxresdefault.jpg" > youtube_video_thumbnail.jpg
            print "\nThe thumbnail was save to ${YELLOW}youtube_video_thumbnail.jpg${NOFORMAT}\n"
        else
            error "No video URL was entered."
        fi

    fi
done

#
# Quitting
#
echo ""
say "Goodbye my lover"
say "Goodbye my friend"
say "You have been the one"
say "You have been the one for me"
