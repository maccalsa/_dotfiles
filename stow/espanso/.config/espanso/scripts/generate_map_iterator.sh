#!/bin/bash

LANG_TYPE="$1"

[[ -z "$LANG_TYPE" ]] && { echo "Usage: $0 <language>"; exit 1; }

map_var=$(zenity --entry --title="${LANG_TYPE^} Map Iterator" --text="Map variable name:")

[[ -z "$map_var" ]] && { zenity --error --text="Map variable required."; exit 1; }

case "$LANG_TYPE" in
    python)
        snippet="for k, v in ${map_var}.items():\n    print(f\"{k}: {v}\")"
        ;;
    java)
        snippet="${map_var}.forEach((k, v) -> System.out.println(k + \": \" + v));"
        ;;
    kotlin)
        snippet="${map_var}.forEach { (k, v) -> println(\"\$k: \$v\") }"
        ;;
    typescript)
        snippet="${map_var}.forEach((v, k) => console.log(`${k}: ${v}`));"
        ;;
    go)
        snippet="for k, v := range ${map_var} {\n    fmt.Printf(\"%v: %v\\n\", k, v)\n}"
        ;;
    *)
        zenity --error --text="Unsupported language: $LANG_TYPE"; exit 1 ;;
esac

echo -e "$snippet"
