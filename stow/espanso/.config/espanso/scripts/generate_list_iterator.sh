#!/bin/bash

LANG_TYPE="$1"

[[ -z "$LANG_TYPE" ]] && { echo "Usage: $0 <language>"; exit 1; }

list_var=$(zenity --entry --title="${LANG_TYPE^} List Iterator" --text="List variable name:")

[[ -z "$list_var" ]] && { zenity --error --text="List variable required."; exit 1; }

case "$LANG_TYPE" in
    python)
        snippet="for item in ${list_var}:\n    print(item)"
        ;;
    java)
        snippet="for(var item : ${list_var}) {\n    System.out.println(item);\n}"
        ;;
    kotlin)
        snippet="${list_var}.forEach { println(it) }"
        ;;
    typescript)
        snippet="${list_var}.forEach(item => console.log(item));"
        ;;
    go)
        snippet="for _, item := range ${list_var} {\n    fmt.Println(item)\n}"
        ;;
    *)
        zenity --error --text="Unsupported language: $LANG_TYPE"; exit 1 ;;
esac

echo -e "$snippet"
