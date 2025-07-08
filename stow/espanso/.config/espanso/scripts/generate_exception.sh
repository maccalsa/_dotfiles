#!/bin/bash
LANG="$1"

case "$LANG" in
  python)
    snippet="try:\n    pass\nexcept Exception as e:\n    print(e)"
    ;;
  java|kotlin|typescript)
    snippet="try {\n    \n} catch (Exception e) {\n    e.printStackTrace();\n}"
    ;;
  go)
    snippet="result, err := SomeFunc()\nif err != nil {\n    log.Println(err)\n}"
    ;;
  *)
    zenity --error --text="Unsupported language."; exit 1 ;;
esac

echo -e "$snippet"
