#!/bin/bash
LANG="$1"
filename=$(zenity --entry --title="${LANG^} File Read/Write" --text="Enter file name:")

case "$LANG" in
  python)
    snippet="# Read\nwith open('${filename}', 'r') as file:\n    data = file.read()\n\n# Write\nwith open('${filename}', 'w') as file:\n    file.write('data')"
    ;;
  java)
    snippet="// Read\nFiles.readString(Paths.get(\"${filename}\"));\n\n// Write\nFiles.writeString(Paths.get(\"${filename}\"), \"data\");"
    ;;
  kotlin)
    snippet="// Read\nval data = File(\"${filename}\").readText()\n\n// Write\nFile(\"${filename}\").writeText(\"data\")"
    ;;
  typescript)
    snippet="// Requires fs module\nimport fs from 'fs';\n\n// Read\nconst data = fs.readFileSync('${filename}', 'utf8');\n\n// Write\nfs.writeFileSync('${filename}', 'data');"
    ;;
  go)
    snippet="// Read\ndata, err := os.ReadFile(\"${filename}\")\nif err != nil {\n    log.Fatal(err)\n}\n\n// Write\nerr = os.WriteFile(\"${filename}\", []byte(\"data\"), 0644)\nif err != nil {\n    log.Fatal(err)\n}"
    ;;
  *)
    zenity --error --text="Unsupported language."; exit 1 ;;
esac

echo -e "$snippet"
