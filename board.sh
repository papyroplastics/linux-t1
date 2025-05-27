#!/usr/bin/env bash

source ./common.sh
function _create_files {
    local path="$1"
    local count="$2"
    local i

    for (( i = 1; i <= count; i++ )); do
        local filename="$path/$(_random_chars 10)"
        while [[ -e "$filename" ]]; do 
            filename="$path/$(_random_chars 10)"
        done
        touch "$filename"
    done
}

function _create_board_recur {
    local path="$1"
    local depth=$(($2 - 1))
    local width="$3"
    local files="$4"
    local i

    if [[ $depth -gt 0 ]]; then
        for (( i = 1; i <= width; i++ )); do
            mkdir -p "$path/$i"
            _create_board_recur "$path/$i" "$depth" "$width" "$files"
        done
    else
        for (( i = 1; i <= width; i++ )); do
            mkdir -p "$path/$i"
            _create_files "$path/$i" "$files"
        done
    fi
}

function create_board {
    if [[ $# -ne 3 ]]; then
        echo "error (create_board): incorrect number of parameters ($#), must be 3." 1>&2
        echo "use: create_board <depth> <width> <files>" 1>&2
        return 1
    fi

    local depth="$1"
    local width="$2"
    local files="$3"
    if ! _is_int "$depth"; then
        echo "error (create_board): parameter 'depth' must be a positive integer." 1>&2
        return 1
    elif ! _is_int "$width"; then
        echo "error (create_board): parameter 'width' must be a positive integer." 1>&2
        return 1
    elif ! _is_int "$files"; then
        echo "error (create_board): parameter 'files' must be a positive integer." 1>&2
        return 1
    fi

    clean_board
    mkdir -p "$BOARD_DIR"
    _create_board_recur "$BOARD_DIR" "$depth" "$width" "$files"
}

function clean_board {
    if [[ $# -ne 0 ]]; then
        echo "error (clean_board): incorrect number of parameters ($#), must be 0." 1>&2
        return 1
    fi

    if [[ -d "$BOARD_DIR" ]]; then
        rm -rf "$BOARD_DIR"
    fi
}

function _fill_board_recur {
    local dir="$1"
    local post_command="$2"
    local post_argument="$3"

    for name in "$dir"/*; do
        if [[ -d "$name" ]]; then
            _fill_board_recur "$name" "$post_command" "$post_argument"
        elif [[ -f "$name" ]]; then
            _fill_file "$name"
            "$post_command" "$name" "$post_argument"
        fi
    done
}

function fill_board {
    if [[ $# -ne 1 ]]; then
        echo "error (fill_board): incorrect number of parameters ($#), must be 1." 1>&2
        echo "use: fill_board <game mode>" 1>&2
        return 1
    elif [[ ! -d "$BOARD_DIR" ]]; then
        echo "error (fill_board): \"$BOARD_DIR\" directory does not exist." 1>&2
        return 1
    elif [[ -f "$_mode_path" ]]; then
        echo "error (fill_board): board has already been filled." 1>&2
        return 1
    fi

    local mode="$1"
    mkdir -p "$_meta_dir"
    echo "$mode" > "$_mode_path"

    case "$mode" in
        name | content | checksum)
            _fill_board_recur "$BOARD_DIR" 'true' '';;
        encrypted)
            _random_chars 20 > "$_common_pass_path"
            _fill_board_recur "$BOARD_DIR" '_encrypt_file' "$_common_pass_path"
            ;;
        signed)
            _gen_key_pair $_common_privkey_path $_common_pubkey_path
            _fill_board_recur "$BOARD_DIR" '_sign_file' "$_common_privkey_path"
            ;;
        *) 
            echo "error (fill_board): invalid game mode \"$mode\", \
must be one of (name, content, checksum, encrypted, signed)" 1>&2
            rm "$_mode_path"
            return 1
            ;;
    esac
}

case "$1" in
    create_board | clean_board | fill_board) $*;;
    '') echo "error ($0): no command was suplied." 1>&2;;
    *) echo "error ($0): invalid command \"$1\"." 1>&2;;
esac

