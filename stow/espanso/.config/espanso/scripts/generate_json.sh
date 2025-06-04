#!/bin/bash
LANG="$1"

case "$LANG" in
  python)
    snippet="import json\n\n# Serialize\njson_str = json.dumps(obj)\n\n# Deserialize\nobj = json.loads(json_str)"
    ;;
  java|kotlin)
    snippet="// Use Jackson\nObjectMapper mapper = new ObjectMapper();\n\n// Serialize\nString json = mapper.writeValueAsString(obj);\n\n// Deserialize\nMyClass obj = mapper.readValue(json, MyClass.class);"
    ;;
  typescript)
    snippet="// Serialize\nconst jsonString = JSON.stringify(obj);\n\n// Deserialize\nconst obj = JSON.parse(jsonString);"
    ;;
  go)
    snippet="// Serialize\njsonBytes, _ := json.Marshal(obj)\n\n// Deserialize\njson.Unmarshal(jsonBytes, &obj)"
    ;;
  *)
    zenity --error --text="Unsupported language"; exit 1 ;;
esac

echo -e "$snippet"
