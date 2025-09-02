#!/bin/bash

# Usage: ./combine_files.sh [directory] [output_file] [patterns] [ignore_dirs]
# Example: ./combine_files.sh . combined.txt "*.rs,*.toml" "node_modules,target,.git"

# Default values
DIR="${1:-.}"
OUTPUT="${2:-combined_output.txt}"
PATTERNS="${3:-*}"
IGNORE_DIRS="${4:-}"

# Verify directory exists
if [[ ! -d "$DIR" ]]; then
    echo "Error: Directory '$DIR' not found"
    exit 1
fi

# Convert directory to absolute path
DIR=$(cd "$DIR" && pwd)
OUTPUT="$DIR/$OUTPUT"

# Create/clear output file
> "$OUTPUT"

# Convert comma-separated patterns into find -name arguments
pattern_args=()
IFS=',' read -ra patterns <<< "$PATTERNS"
for pattern in "${patterns[@]}"; do
    pattern="${pattern## }"  # trim leading spaces
    pattern="${pattern%% }"  # trim trailing spaces
    pattern_args+=(-name "$pattern")
    pattern_args+=(-o)
done
# Remove last -o from pattern_args
unset 'pattern_args[${#pattern_args[@]}-1]'

# Convert comma-separated ignore directories into find -prune arguments
prune_expr=""
if [[ -n "$IGNORE_DIRS" ]]; then
    prune_parts=()
    IFS=',' read -ra ignore_patterns <<< "$IGNORE_DIRS"
    for ignore_pattern in "${ignore_patterns[@]}"; do
        ignore_pattern="${ignore_pattern## }"  # trim leading spaces
        ignore_pattern="${ignore_pattern%% }"  # trim trailing spaces
        prune_parts+=("-name" "$ignore_pattern" "-o")
    done
    # Remove last -o
    unset 'prune_parts[${#prune_parts[@]}-1]'
    prune_expr="\( ${prune_parts[*]} \) -prune -o"
fi

# Construct the find command
if [[ -n "$prune_expr" ]]; then
    find_cmd="find \"$DIR\" $prune_expr -type f \( ${pattern_args[*]} \) -not -path \"$OUTPUT\" -print0"
else
    find_cmd="find \"$DIR\" -type f \( ${pattern_args[*]} \) -not -path \"$OUTPUT\" -print0"
fi

# Execute the find command and process files
eval "$find_cmd" | while IFS= read -r -d '' file; do
    # Get relative path for cleaner output
    rel_path="${file#$DIR/}"
    
    # Skip if file is not readable
    if [[ ! -r "$file" ]]; then
        echo "Warning: Cannot read '$rel_path' - skipping"
        continue
    fi
    
    echo "Processing: $rel_path"
    
    # Write to output file with markers
    echo "--- START OF FILE: $rel_path ---" >> "$OUTPUT"
    cat "$file" >> "$OUTPUT"
    echo -e "\n--- END OF FILE: $rel_path ---\n" >> "$OUTPUT"
done

echo "Done! Output written to: $OUTPUT"
