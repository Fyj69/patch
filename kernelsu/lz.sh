#!/bin/bash

FILE=$1

[ -f "$FILE" ] || {
	echo "Provide a config file as argument"
	exit 1
}

CONFIGS_ON="
CONFIG_CRYPTO_LZ4K=y
CONFIG_CRYPTO_LZ4KD=y
CONFIG_CRYPTO_LZ4K_OPLUS=y
"
append_config() {
    local config="$1"
    if ! grep -q "^${config}" "$FILE"; then
        echo "Adding: $config"
        echo "$config" >> "$FILE"
    else
        echo "Already exists: $config"
    fi
}

echo "Checking and appending configurations to $FILE..."

while IFS= read -r config; do
    [ -n "$config" ] && append_config "$config"
done <<< "$CONFIGS_ON"

echo "Done: Configuration file has been updated."
