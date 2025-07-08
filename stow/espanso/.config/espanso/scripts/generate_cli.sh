#!/bin/bash
LANG="$1"

case "$LANG" in
  python)
    snippet="import argparse\nparser = argparse.ArgumentParser()\nparser.add_argument('--arg')\nargs = parser.parse_args()"
    ;;
  java|kotlin)
    snippet="// Basic args handling\npublic static void main(String[] args) {\n    for(String arg : args) System.out.println(arg);\n}"
    ;;
  typescript)
    snippet="// Use minimist or commander\nconst args = process.argv.slice(2);"
    ;;
  go)
    snippet="import \"flag\"\nvar arg = flag.String(\"arg\", \"default\", \"Description\")\nflag.Parse()"
    ;;
  *)
    zenity --error --text="Unsupported language"; exit 1 ;;
esac

echo -e "$snippet"
