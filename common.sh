#!/usr/bin/env bash

if [[ -z "$BOARD_DIR" ]]; then
    export BOARD_DIR='./board'
fi

shopt -s extglob # pattern matching extendido
shopt -u dotglob # ignorar dotfiles en expansiones

_meta_dir="$BOARD_DIR/.meta"

_mode_path="$_meta_dir/mode.txt"

_treasure_chksum_path="$_meta_dir/treasure_chksum.txt"

_common_pass_path="$_meta_dir/common_pass.txt"
_treasure_pass_path="$_meta_dir/treasure_pass.txt"

_common_privkey_path="$_meta_dir/common_privkey.pem"
_common_pubkey_path="$_meta_dir/common_pubkey.pem"
_treasure_privkey_path="$_meta_dir/treasure_privkey.pem"
_treasure_pubkey_path="$_meta_dir/treasure_pubkey.pem"

_gpg_flags='--quiet --batch --no-symkey-cache --pinentry-mode loopback'
_checksum_command='sha1sum'

_valid_random_chars=($(echo {a..z} {A..Z} {0..9} - _ ))
_valid_random_char_count="${#_valid_random_chars[@]}"

function _random_chars {
    local count="$1"

    for (( i = 1; i <= count; i++ )); do
        index=$((RANDOM % $_valid_random_char_count))
        echo -n "${_valid_random_chars[index]}"
    done
}

function _fill_file {
    local name="$1"
    local charnum=$(( (RANDOM % 200) + 100 ))
    _random_chars "$charnum" > "$name"
}

function _is_int {
    case "$1" in
        +([0-9])) return 0;;
        *) return 1;;
    esac
}

function _encrypt_file {
    local name="$1"
    local pass="$2"
    gpg $_gpg_flags --passphrase-file "$pass" --output "$name.tmp" --symmetric "$name"
    mv -f "$name.tmp" "$name"
}

function _decrypt_file {
    local name="$1"
    local pass="$2"
    gpg $_gpg_flags --passphrase-file "$pass" --output - --decrypt "$name" 2>/dev/null
    return $?
}

function _gen_key_pair {
    local privkey="$1"
    local pubkey="$2"
    openssl genpkey -algorithm RSA -out "$privkey"
    openssl rsa -pubout -in "$privkey" -out "$pubkey"
}

function _signature_path {
    local path="$1"
    local dir="${path%/*}"
    local file="${path##*/}"
    if [[ "$dir" == "$path" ]]; then
        echo ".${path}.sig"
    else
        echo "${dir}/.${file}.sig"
    fi
}

function _sign_file {
    local name="$1"
    local priv_key="$2"
    openssl dgst -sha256 -sign "$priv_key" -out "$(_signature_path "$name")" "$name" &>/dev/null
}

function _verify_file {
    local name="$1"
    local pub_key="$2"
    openssl dgst -sha256 -verify "$pub_key" -signature "$(_signature_path "$name")" "$name" &>/dev/null
    return $?
}


