#!/bin/bash
LANG="$1"
condition=$(zenity --entry --title="${LANG^} If-Else" --text="Enter condition:")

case "$LANG" in
  python)
    snippet="if ${condition}:\n    pass\nelse:\n    pass"
    ;;
  java|kotlin|typescript|go)
    snippet="if (${condition}) {\n    \n} else {\n    \n}"
    ;;
  *)
    zenity --error --text="Unsupported language."; exit 1 ;;
esac

echo -e "$snippet"
