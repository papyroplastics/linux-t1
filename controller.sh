#!/usr/bin/env bash

source ./common.sh

function _chose_file {
    entries=( "$1/"* )
    index=$(( $RANDOM % "${#entries[*]}" ))
    name=${entries[index]}

    if [[ -d "$name" ]]; then
        _chose_file "$name"
    elif [[ -f "$name" ]]; then
        while 
        echo "$name"
    fi
}

function place_treasure {
    if [[ ! -d "$_board_dir" ]]; then
        echo "error: board does not exist." 1>&2
        return 1
    fi

    file="$(_chose_file_recur "$BOARD_DIR")"
    mode=$(< "$_mode_path")

    case "$mode" in
        name) echo "${file##*/}" ;;
        content) cat "$file" ;;
        checksum)
            checksum=($($_checksum_command "$file"))
            echo ${checksum[0]}
            ;;
        encrypted) 
            _fill_file "$file"
            _random_chars 10 > "$_treasure_pass_path"
            ;;
        signed) 
            _gen_key_pair "$_treasure_privkey_path" "$_treasure_pubkey_path"
            _sign_file "$name" "$_treasure_privkey_path"
            ;;
        *) 
            echo "error (place_treasure): modo invalido ($mode)."
    esac

}

