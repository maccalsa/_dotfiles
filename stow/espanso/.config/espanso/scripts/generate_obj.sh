#!/bin/bash

LANG_TYPE="$1"

[[ -z "$LANG_TYPE" ]] && { echo "Usage: $0 <language>"; exit 1; }

# --- Single form dialog ---
form_input=$(zenity --forms \
    --title="${LANG_TYPE^} Object Generator" \
    --text="Enter details for ${LANG_TYPE^} object:" \
    --width=550 --height=350 \
    --add-entry="Name" \
    --add-entry="Parameters (comma-separated: name:type)" \
    --add-entry="Inherits (optional, comma-separated)" \
    --add-entry="Interfaces (optional, comma-separated, Java/Kotlin/TypeScript only)" \
    --add-combo="Type (Go only)" --combo-values="struct|interface|func" \
    --add-combo="Data Class (Kotlin only)" --combo-values="no|yes" \
    --add-combo="Include Constructor" --combo-values="yes|no")

[[ $? -ne 0 ]] && exit 1

# --- Extract fields ---
IFS='|' read -r obj_name raw_params inherits interfaces go_type is_data_class constructor <<< "$form_input"

[[ -z "$obj_name" ]] && { zenity --error --text="Object name is required."; exit 1; }

# --- Parameter Formatter ---
format_params() {
    local input="$1"
    local lang="$2"
    local formatted=()

    while IFS= read -r param; do
        param=$(echo "$param" | xargs)
        [[ -z "$param" ]] && continue
        case "$lang" in
            go|java|kotlin|typescript)
                [[ ! "$param" =~ [[:space:]] ]] && param="$param TYPE"
                formatted+=("$param")
                ;;
            python)
                formatted+=("$param")
                ;;
        esac
    done <<< "$(echo "$input" | tr ',' '\n' | tr ':' ' ')"

    (IFS=', '; echo "${formatted[*]}")
}

formatted_params=$(format_params "$raw_params" "$LANG_TYPE")

# --- Generate Code ---
case "$LANG_TYPE" in
    python)
        inherit_clause=""
        [[ -n "$inherits" ]] && inherit_clause="($(echo $inherits | tr ',' ','))"
        generated_code="class ${obj_name}${inherit_clause}:\n"
        if [[ "$constructor" == "yes" && -n "$formatted_params" ]]; then
            generated_code+="    def __init__(self, ${formatted_params}):\n"
            generated_code+="        pass\n\n"
        fi
        generated_code+="    def hello_world(self):\n"
        generated_code+="        print(\"Hello World\")\n"
        ;;
    java)
        [[ -n "$inherits" ]] && inherits="extends ${inherits}"
        [[ -n "$interfaces" ]] && interfaces="implements $(echo $interfaces | tr ',' ',')"
        generated_code="public class ${obj_name} ${inherits} ${interfaces} {\n"
        if [[ "$constructor" == "yes" ]]; then
            generated_code+="    public ${obj_name}(${formatted_params}) {\n"
            generated_code+="    }\n"
        fi
        generated_code+="\n    public void helloWorld() {\n"
        generated_code+="        System.out.println(\"Hello World\");\n"
        generated_code+="    }\n}"
        ;;
    kotlin)
        class_type="class"
        [[ "$is_data_class" == "yes" ]] && class_type="data class"
        inherit_clause=""
        [[ -n "$inherits" ]] && inherit_clause=": ${inherits}()"
        [[ -n "$interfaces" ]] && inherit_clause+=","$(echo $interfaces | tr ',' ',')
        generated_code="${class_type} ${obj_name}(${formatted_params}) ${inherit_clause} {\n"
        generated_code+="    fun helloWorld() = println(\"Hello World\")\n}"
        ;;
    typescript)
        inherit_clause=""
        [[ -n "$inherits" ]] && inherit_clause="extends ${inherits}"
        [[ -n "$interfaces" ]] && inherit_clause+=" implements "$(echo $interfaces | tr ',' ',')
        generated_code="class ${obj_name} ${inherit_clause} {\n"
        if [[ "$constructor" == "yes" ]]; then
            generated_code+="    constructor(${formatted_params}) {}\n"
        fi
        generated_code+="\n    helloWorld(): void {\n"
        generated_code+="        console.log(\"Hello World\");\n"
        generated_code+="    }\n}"
        ;;
    go)
        case "$go_type" in
            struct)
                generated_code="type ${obj_name} struct {\n"
                for param in $(echo "$formatted_params" | tr ',' '\n'); do
                    generated_code+="    $param\n"
                done
                generated_code+="}\n\n"
                [[ "$constructor" == "yes" ]] && {
                    generated_code+="func New${obj_name}(${formatted_params}) *${obj_name} {\n"
                    generated_code+="    return &${obj_name}{}\n}\n\n"
                }
                generated_code+="func (o *${obj_name}) HelloWorld() {\n"
                generated_code+="    fmt.Println(\"Hello World\")\n}\n"
                ;;
            interface)
                generated_code="type ${obj_name} interface {\n"
                generated_code+="    HelloWorld()\n}\n"
                ;;
            func)
                generated_code="func ${obj_name}(${formatted_params}) {\n"
                generated_code+="    fmt.Println(\"Hello World\")\n}\n"
                ;;
        esac
        ;;
    *)
        zenity --error --text="Unsupported language: $LANG_TYPE"; exit 1 ;;
esac

echo -e "$generated_code"
