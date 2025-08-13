#!/bin/sh

# Utility function for replacing a key's
# value in-place in a JSON document.
replace_key_value()
{  
    local json_path=$1
    local key=$2
    local value=$3
    local new_json="$(jq ".${key} = ${value}" ${json_path})"
    echo -E ${new_json} > ${json_path}
}

# Change the default browser title text;
# the --app-name argument to code-server
# only changes the login screen text
# (https://github.com/coder/code-server/pull/5633).
WORKBENCH_PATH=/usr/lib/code-server/lib/vscode/out/vs/workbench
WORKBENCH_NAME=Workbench
JSON_PATH=/usr/lib/code-server/lib/vscode/product.json
replace_key_value $JSON_PATH nameShort "\"${WORKBENCH_NAME}\""
replace_key_value $JSON_PATH nameLong "\"${WORKBENCH_NAME}\""
replace_key_value $JSON_PATH applicationName "\"${WORKBENCH_NAME}\""

# Disable telemetry at the package level.
replace_key_value $JSON_PATH enableTelemetry false

# Restyle the application icons.
ICON_PATH=/usr/lib/code-server/src/browser/media
cp caer-icon.ico $ICON_PATH/favicon.ico
cp caer-icon.svg $ICON_PATH/favicon.svg
cp caer-icon.svg $ICON_PATH/favicon-dark-support.svg
cp caer-icon-squircle-192.png $ICON_PATH/pwa-icon-192.png
cp caer-icon-squircle-512.png $ICON_PATH/pwa-icon-512.png
cp caer-icon-squircle-540.png $ICON_PATH/pwa-icon.png

# Restyle the background graphic that is rendered when
# no files are open in the editor (the "letterpress").
WORKBENCH_PATH_CSS=$WORKBENCH_PATH/workbench.web.main.css
REPL=$(cat caer.svg.base64)
REPL="data:image\/svg+xml;base64,$REPL"

# Match all instances of the letterpress.
EXPR='(letterpress\s*\{\s*.*?background-image:\s*url)\("(.*?)"\)'
EXPR="s/$EXPR/\$1(\"$REPL\")/g"
perl -i -pe $EXPR $WORKBENCH_PATH_CSS
# Match the dark theme letterpress.
# EXPR=\(vs-dark.*?letterpress\s*\\{\s*.*?background-image:\s*url\)\("(.*?)"\)
# Match the high-contrast light theme letterpress.
# EXPR=\(hc-light.*?letterpress\s*\\{\s*.*?background-image:\s*url\)\("(.*?)"\)
# Match the high-contrast dark theme letterpress.
# EXPR=\(hc-black.*?letterpress\s*\\{\s*.*?background-image:\s*url\)\("(.*?)"\)

# Potentially fix cursor duplication bug on iPadOS.
# Related issue: https://github.com/microsoft/vscode/issues/121195
EXPR='(monaco-editor\s*\.inputarea\s*\{)'
EXPR="s/$EXPR/\$1-webkit-user-select:none;-user-select:none;/g"
perl -i -pe $EXPR $WORKBENCH_PATH_CSS

# Install Fira Code fonts.
# https://github.com/tuanpham-dev/code-server-font-patch/blob/master/patch.sh
cp -rn fonts/*.ttf $WORKBENCH_PATH/
cat fonts/inconsolata.css >> $WORKBENCH_PATH_CSS

# TODO: Restyle the Welcome page
# https://github.com/coder/code-server/blob/095c072a43e6abf4eee163d81af9115d7000c4ce/patches/getting-started.diff#L35

