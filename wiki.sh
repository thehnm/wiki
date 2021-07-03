#!/usr/bin/env bash

bold=$(tput bold)
normal=$(tput sgr0)

fzfcmd() {
    fzf --preview 'bat --style=numbers --color=always $(echo {} | cut -d " " -f1).md'
}

printoptions() {
    printf "%s\n\n" "The following options are available"
    [ -n "$currid" ] && printf "%s\n" "- [e] edit current note"
    [ -n "$currid" ] && printf "%s\n" "- [l] link current note with another note"
    [ -n "$currid" ] && printf "%s\n" "- [f] display links for current note"
    printf "%s\n" "- [a] list all files"
    printf "%s\n" "- [n] create new file"
    printf "%s\n" "- [q] quit"
    printf "\n"
}

listfiles() {
    sel=$(head -1q "$dir"/* | cut -d " " -f2- | fzfcmd)
    [ -z "$sel" ] && return
    currid=$(printf "$sel" | cut -d " " -f1)
    currfile="$currid".md
    currtitle=$(head -1q "$dir/$currfile" | cut -d " " -f2-)
}

linkfiles() {
    lsel=$(head -1q "$dir"/* | fzfcmd)
    [ -z "$lsel" ] && return
    lid=$(printf "$lsel" | cut -d " " -f2)
    lfile="$lid".md
    ltitle=$(head -1q "$dir/$lfile" | cut -d " " -f2-)

    [ -z "$(grep '## Links' "$dir/$currfile")" ] && printf "\n## Links\n" >> "$dir/$currfile"
    printf "%s\n" "- $ltitle" >> "$dir/$currfile"

    [ -z "$(grep '## Links' "$dir/$lfile")" ] && printf "\n## Links\n" >> "$dir/$lfile"
    printf "%s\n" "- $currtitle" >> "$dir/$lfile"
}

followlinks() {
    links=$(sed -e '1,/## Links/d' $dir/$currfile | sed 's/- //g')
    currtitle=$(printf "$links" | fzf --preview 'bat --style=numbers --color=always $(echo {} | cut -d " " -f1).md')
    [ -z "$currtitle" ] && return
    currid=$(printf $currtitle | cut -d " " -f1)
    currfile="$currid".md
}

wronginput() {
    printf "$1\n"
    printf "Press any key to continue\n"
    while true; do
        read -t 3 -n 1
        if [ $? = 0 ] ; then
            return ;
        else
            printf "Waiting for the keypress\n"
        fi
    done
}

newfile() {
    fileid=$(date +'%y%m%d%H%M%S')
    touch $dir/"$fileid".md
    echo "# $fileid - TITLE" > $dir/"$fileid".md
    $EDITOR $dir/"$fileid.md"
    currfile="$fileid".md
    currid=$fileid
}

menu() {
    clear
    [ -n "$currid" ] && currtitle=$(head -1q "$dir/$currfile" | cut -d " " -f2-) && bat -p "$dir/$currfile"
    printf "\n"
    printoptions
    read -p "Enter your choice: " choice
    case $choice in
        e) [ -z "$currid" ] && wronginput "No file currently selected!" || $EDITOR "$dir/$currfile";;
        l) linkfiles;;
        f) followlinks;;
        a) listfiles;;
        n) newfile;;
        q) exit;;
        *) wronginput "Please enter a valid choice!"; break;;
    esac
}

if [ -n "$1" ]; then
    dir="$1"
else
    dir="./"
fi

listfiles
while true; do
    menu
done
