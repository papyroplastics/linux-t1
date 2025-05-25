#!/usr/bin/env bash

source ./common.sh

function _chose_file {
    local entries=( "$1/"* )
    local index=$(( $RANDOM % "${#entries[*]}" ))
    local name=${entries[index]}

    if [[ -d "$name" ]]; then
        _chose_file "$name"
    elif [[ -f "$name" ]]; then
        echo "$name"
    fi
}

function place_treasure {
    if [[ $# -ne 0 ]]; then
        echo "error (place_treasure): incorrect number of parameters ($#), must be 0." 1>&2
        return 1
    elif [[ ! -d "$BOARD_DIR" ]]; then
        echo "error (place_treasure): board does not exist." 1>&2
        return 1
    elif [[ ! -f "$_mode_path" ]]; then
        echo "error (place_treasure): no game mode selected." 1>&2
        return 1
    fi

    local file="$(_chose_file "$BOARD_DIR")"
    local mode="$(cat "$_mode_path")"

    if [[ -z "$mode" ]]; then
        echo "error (place_treasure): game mode is empty." 1>&2
        return 1
    fi

    case "$mode" in
        name) 
            local filename="${file##*/}"
            echo "$filename" > "$_treasure_filename_path"
            echo "File name: $filename"
            ;;
        content) 
            cp "$file" "$_treasure_content_path"
            echo "File contents: "
            cat "$file" 
            echo 
            ;;
        checksum)
            local checksum="$(_checksum_file "$file")"
            echo "$checksum" > "$_treasure_chksum_path"
            echo "File checksum: $checksum"
            ;;
        encrypted) 
            _fill_file "$file"
            local passphrase="$(_random_chars 10)"
            echo "$passphrase" > "$_treasure_pass_path"
            _encrypt_file "$file" "$_treasure_pass_path"
            echo "Selected passphrase: $passphrase"
            ;;
        signed) 
            _gen_key_pair "$_treasure_privkey_path" "$_treasure_pubkey_path"
            _sign_file "$file" "$_treasure_privkey_path"
            echo "Public key of the treasure:"
            cat "$_treasure_pubkey_path"
            ;;
        *) 
            echo "error (place_treasure): invalid mode ($mode)." 1>&2
            return 1
    esac
}

function verify {
    if [[ $# -ne 1 ]]; then
        echo "error (verify): incorrect number of parameters ($#), must be 1." 1>&2
        return 1
    elif [[ ! -d "$BOARD_DIR" ]]; then
        echo "error (verify): board does not exist." 1>&2
        return 1
    elif [[ ! -f "$_mode_path" ]]; then
        echo "error (verify): no game mode selected." 1>&2
        return 1
    fi

    local mode="$(cat "$_mode_path")"
    if [[ -z "$mode" ]]; then
        echo "error (verify): game mode is empty." 1>&2
        return 1
    fi

    local file="$1"
    if [[ ! -e "$file" ]]; then
        echo "error (verify): file \"$file\" does not exist." 1>&2
        return 1
    elif [[ ! -f "$file" ]]; then
        echo "error (verify): \"$file\" is not a regular file." 1>&2
        return 1
    elif [[ "$(realpath "$file")" != "$(realpath "$BOARD_DIR")"/* ]]; then
        echo "error (verify): \"$file\" is not inside the board." 1>&2
        return 1
    fi


    case "$mode" in
        name) [[ "${file##*/}" == "$(cat $_treasure_filename_path)" ]];;
        content) [[ "$(cat "$file")" == "$(cat "$_treasure_content_path")" ]];;
        checksum) [[ "$(_checksum_file "$file")" == "$(cat "$_treasure_chksum_path")" ]];;
        encrypted) _decrypt_file "$file" "$_treasure_pass_path";;
        signed) _verify_file "$file" "$_treasure_pubkey_path";;
        *) echo "error (verify): invalid mode ($mode)." 1>&2; return 1;;
    esac

    if [[ $? -eq 0 ]]; then
        echo "Treasure found!"
        return 0
    else
        echo "Incorrect guess."
        return 1
    fi
}


case "$1" in
    place_treasure | verify ) $*;;
    '') echo "error ($0): no command was suplied." 1>&2;;
    *) echo "error ($0): invalid command \"$1\"." 1>&2;;
esac

