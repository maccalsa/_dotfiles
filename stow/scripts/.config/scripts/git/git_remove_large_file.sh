#!/bin/bash
# remove_file.sh
# Usage: ./remove_file.sh path/to/largefile

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 path/to/largefile"
    exit 1
fi

FILE_TO_REMOVE="$1"

echo "Removing '$FILE_TO_REMOVE' from all commits..."

# Remove the file from every commit in the history.
git filter-branch --force --index-filter \
"git rm --cached --ignore-unmatch \"$FILE_TO_REMOVE\"" \
--prune-empty --tag-name-filter cat -- --all

echo "Cleaning up backup references..."
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo "The file '$FILE_TO_REMOVE' has been removed from the repository history."
echo "To push these changes, run: git push --force"
