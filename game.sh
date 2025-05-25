#!/usr/bin/env bash

shopt -s extglob # pattern matching extendido
shopt -u dotglob # ignorar dotfiles en expansiones

if [[ $# -ne 4 ]]; then 
    echo "use: $0 <depth> <width> <files> <mode>" 1>&2
    exit 0
fi

depth="$1"
width="$2"
files="$3"
mode="$4"

./board.sh create_board "$depth" "$width" "$files" || exit 1
./board.sh fill_board "$mode" || exit 1

./controller.sh place_treasure || exit 1 

echo "Take a guess after the prompt:"
echo -n '> '

while read -e guess; do
    ./controller.sh verify "$guess" && exit 0
    echo -n '> '
done

echo "Exited prematurely."
exit 1

