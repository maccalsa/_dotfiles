#!/bin/bash

LANG_TYPE="$1"

[[ -z "$LANG_TYPE" ]] && { echo "Usage: $0 <language>"; exit 1; }

# --- Helper to format parameters neatly based on language ---
format_params() {
    local input="$1"
    local lang="$2"
    local formatted_params=()

    while IFS= read -r param; do
        param=$(echo "$param" | xargs)  # trim whitespace
        [[ -z "$param" ]] && continue

        case "$lang" in
            go|typescript|kotlin|java)
                # Ensure parameters have a type after the name
                if [[ ! "$param" =~ [[:space:]] ]]; then
                    param="$param TYPE"
                fi
                formatted_params+=("$param")
                ;;
            python)
                # Python parameters may not have types
                formatted_params+=("$param")
                ;;
        esac
    done <<< "$(echo "$input" | tr ',' '\n' | tr ':' ' ')"

    (IFS=', '; echo "${formatted_params[*]}")
}

# --- Single Form Dialog to Get Inputs ---
form_input=$(zenity --forms \
    --title="${LANG_TYPE^} Function Generator" \
    --text="Enter function details for ${LANG_TYPE^}:" \
    --width=500 \
    --height=300 \
    --add-entry="Function Name" \
    --add-entry="Parameters (comma-separated: name:type)" \
    --add-entry="Return Type(s) (optional)")

[[ $? -ne 0 ]] && exit 1  # User cancelled

# --- Extract form fields ---
IFS='|' read -r func_name raw_params return_type <<< "$form_input"
[[ -z "$func_name" ]] && { zenity --error --text="Function name is required."; exit 1; }

# --- Format Parameters ---
formatted_params=$(format_params "$raw_params" "$LANG_TYPE")

# --- Generate Language-Specific Code ---
case "$LANG_TYPE" in
    go)
        [[ -n "$return_type" ]] && return_type=" $return_type"
        generated_code="func ${func_name}(${formatted_params})${return_type} {\n    $|$\n}"
        ;;
    kotlin)
        [[ -n "$return_type" ]] && return_type=": $return_type"
        generated_code="fun ${func_name}(${formatted_params})${return_type} {\n    $|$\n}"
        ;;
    typescript)
        [[ -n "$return_type" ]] && return_type=": $return_type"
        generated_code="function ${func_name}(${formatted_params})${return_type} {\n    $|$\n}"
        ;;
    python)
        [[ -n "$return_type" ]] && return_type=" -> $return_type"
        generated_code="def ${func_name}(${formatted_params})${return_type}:\n    $|$"
        ;;
    java)
        [[ -z "$return_type" ]] && return_type="void"
        generated_code="public ${return_type} ${func_name}(${formatted_params}) {\n    $|$\n}"
        ;;
    *)
        zenity --error --text="Unsupported language: $LANG_TYPE"
        exit 1
        ;;
esac

# --- Output Generated Code ---
echo -e "$generated_code"
