#!/bin/sh

templates_dir="./templates"
genconf_dir="/opt/template"
config_dir="/gm-server/config"

for template in "$templates_dir"/*.template.js; do
    if [ -f "$template" ]; then
        config_file=$(basename "$template" .template.js).js
        envsubst < "$template" > "$genconf_dir/$config_file"
    fi
done

if [ -d "$config_dir" ] && [ -z "$(ls -A "$config_dir" 2>/dev/null)" ]; then
    \cp -rf "$genconf_dir"/* "$config_dir"
fi

exec "$@"