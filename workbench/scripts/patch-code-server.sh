#!/bin/sh
#
# This patch is up-to-date as of `code-server`
# version: 4.103.0.
#

# Name of the workbench as shown in the browser;
# this name can be set to anything.
WORKBENCH_NAME=Workbench

# Root path to the workbench.
WORKBENCH_PATH=/usr/lib/code-server

# Path to the VS Code product.json file for the workbench.
PRODUCT_JSON_PATH=$WORKBENCH_PATH/lib/vscode/product.json

# Path to the VS Code main CSS file for the workbench.
WORKBENCH_CSS_PARENT_PATH=$WORKBENCH_PATH/lib/vscode/out/vs/code/browser/workbench
WORKBENCH_CSS_PATH=$WORKBENCH_CSS_PARENT_PATH/workbench.css

# Path to the VS Code path containing favicons.
WORKBENCH_ICON_PATH=$WORKBENCH_PATH/src/browser/media

# Path to the VS Code path containing logos.
WORKBENCH_LOGO_PATH=$WORKBENCH_PATH/lib/vscode/out/media

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
replace_key_value $PRODUCT_JSON_PATH nameShort "\"${WORKBENCH_NAME}\""
replace_key_value $PRODUCT_JSON_PATH nameLong "\"${WORKBENCH_NAME}\""
replace_key_value $PRODUCT_JSON_PATH applicationName "\"${WORKBENCH_NAME}\""

# Disable telemetry at the package level.
replace_key_value $PRODUCT_JSON_PATH enableTelemetry false

# Restyle the application favicons.
cp ../assets/icon.ico $WORKBENCH_ICON_PATH/favicon.ico
cp ../assets/icon.svg $WORKBENCH_ICON_PATH/favicon.svg
cp ../assets/icon.svg $WORKBENCH_ICON_PATH/favicon-dark-support.svg
cp ../assets/icon-192.png $WORKBENCH_ICON_PATH/pwa-icon-192.png
cp ../assets/icon-512.png $WORKBENCH_ICON_PATH/pwa-icon-512.png
cp ../assets/icon-540.png $WORKBENCH_ICON_PATH/pwa-icon.png

# Restyle the application logo.
cp ../assets/logo.svg $WORKBENCH_LOGO_PATH/code-icon.svg

# Restyle the background logos that are rendered when
# no files are open in the editor (the "letterpress").
cp ../assets/letterpress.svg $WORKBENCH_LOGO_PATH/letterpress-light.svg
cp ../assets/letterpress.svg $WORKBENCH_LOGO_PATH/letterpress-hcLight.svg
cp ../assets/letterpress.svg $WORKBENCH_LOGO_PATH/letterpress-dark.svg
cp ../assets/letterpress.svg $WORKBENCH_LOGO_PATH/letterpress-hcDark.svg

# Potentially fix cursor duplication bug on iPadOS.
# Related issue: https://github.com/microsoft/vscode/issues/121195
EXPR='(monaco-editor\s*\.inputarea\s*\{)'
EXPR="s/$EXPR/\$1-webkit-user-select:none;-user-select:none;/g"
perl -i -pe $EXPR $WORKBENCH_CSS_PATH

# Install fonts.
# https://github.com/tuanpham-dev/code-server-font-patch/blob/master/patch.sh
cp -rn ../assets/fonts/*.ttf $WORKBENCH_CSS_PARENT_PATH/
cat ../assets/fonts/inconsolata.css | sudo tee -a $WORKBENCH_CSS_PATH

# @caer: todo: Restyle the Welcome page
# https://github.com/coder/code-server/blob/095c072a43e6abf4eee163d81af9115d7000c4ce/patches/getting-started.diff#L35
