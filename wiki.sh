#!/usr/bin/env bash

bold=$(tput bold)
normal=$(tput sgr0)

bf() {
    printf "$bold$1$normal"
}

fzfcmd() {
    str='bat --style=numbers --color=always $(printf "%s" '"$1/"'{} | cut -d " " -f1).md'
    fzf --preview "$str"
}

list() {
    head -1q "$dir"/* | cut -d " " -f2- | fzfcmd "$dir"
}

printoptions() {
    printf "%s\n\n" "The following options are available:"
    [ -n "$currid" ] && printf "%s\n" "- $(bf [e]) edit current note"
    [ -n "$currid" ] && printf "%s\n" "- $(bf [l]) link current note with another note"
    [ -n "$currid" ] && printf "%s\n" "- $(bf [f]) display links for current note"
    [ -n "$currid" ] && printf "%s\n" "- $(bf [d]) delete current note"
    printf "%s\n" "- $(bf [a]) list all files"
    printf "%s\n" "- $(bf [n]) create new file"
    printf "%s\n" "- $(bf [q]) quit"
    printf "\n"
}

selectfile() {
    sel=$(list)
    [ -z "$sel" ] && return
    currid=$(printf "$sel" | cut -d " " -f1)
    currfile="$currid".md
    currtitle=$(head -1q "$dir/$currfile" | cut -d " " -f2-)
}

linkfiles() {
    lsel=$(list)
    [ -z "$lsel" ] && return
    lid=$(printf "$lsel" | cut -d " " -f1)
    lfile="$lid".md
    ltitle=$(head -1q "$dir/$lfile" | cut -d " " -f2-)

    [ -z "$(grep '## Links' "$dir/$currfile")" ] && printf "\n## Links\n" >> "$dir/$currfile"
    printf "%s\n" "- $ltitle" >> "$dir/$currfile"

    [ -z "$(grep '## Links' "$dir/$lfile")" ] && printf "\n## Links\n" >> "$dir/$lfile"
    printf "%s\n" "- $currtitle" >> "$dir/$lfile"
}

followlinks() {
    links=$(sed -e '1,/## Links/d' $dir/$currfile | sed 's/- //g')
    currtitle=$(printf "$links" | fzfcmd "$dir")
    [ -z "$currtitle" ] && return
    currid=$(printf $currtitle | cut -d " " -f1)
    currfile="$currid".md
}

wronginput() {
    printf "$1\n"
    printf "Press any key to continue\n"
    while true; do
        read -t 3 -n 1
        [ $? = 0 ] && return || printf "Waiting for the keypress\n"
    done
}

emptyfilecheck() {
    [ -z "$currid" ] && wronginput "No file currently selected!"
}

newfile() {
    currid=$(date +'%y%m%d%H%M%S')
    touch "$dir/$currid".md
    printf "%s" "# $currid - TITLE" > "$dir/$currid".md
    $EDITOR "$dir/$currid.md"
    currfile="$currid".md
}

deletenote() {
    rm "$dir/$currfile"
    unset currid currfile currtitle
}

menu() {
    clear
    [ -n "$currid" ] && currtitle=$(head -1q "$dir/$currfile" | cut -d " " -f2-) && bat -p "$dir/$currfile"
    printf "\n"
    printoptions
    read -p "Enter your choice: " choice
    case $choice in
        e) emptyfilecheck || $EDITOR "$dir/$currfile";;
        l) emptyfilecheck || linkfiles;;
        f) emptyfilecheck || followlinks;;
        d) emptyfilecheck || (deletenote && selectfile);;
        a) selectfile;;
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

selectfile
while true; do
    menu
done
