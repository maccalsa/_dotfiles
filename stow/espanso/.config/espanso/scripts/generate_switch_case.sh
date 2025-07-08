#!/bin/bash
LANG="$1"
var=$(zenity --entry --title="${LANG^} Switch/Case" --text="Variable to switch on:")

case "$LANG" in
  python)
    snippet="match ${var}:\n    case value1:\n        pass\n    case value2:\n        pass"
    ;;
  java|kotlin|typescript)
    snippet="switch (${var}) {\n    case value1:\n        break;\n    default:\n        break;\n}"
    ;;
  go)
    snippet="switch ${var} {\ncase value1:\n    \ndefault:\n}"
    ;;
  *)
    zenity --error --text="Unsupported language."; exit 1 ;;
esac

echo -e "$snippet"
