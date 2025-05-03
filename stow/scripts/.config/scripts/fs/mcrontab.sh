#!/bin/bash

# Function to create or update a crontab
create_or_update_crontab() {
    echo "Enter the schedule and command for the new or updated crontab entry."
    echo "Example: * * * * * /path/to/command"
    read -p "Schedule and Command: " entry
    (crontab -l 2>/dev/null; echo "$entry") | crontab -
    echo "Crontab updated."
}

# Function to list all crontabs
list_crontabs() {
    echo "Current crontab entries:"
    crontab -l
}

# Function to display the next crontab to run
list_next_crontab() {
    next_cron=$(crontab -l | grep -v '^#' | awk '{print $1,$2,$3,$4,$5}' | sort - | head -1)
    echo "Next scheduled crontab: $next_cron"
}

# Function to delete a crontab
delete_crontab() {
    echo "Current crontab entries:"
    crontab -l
    echo "Copy and paste the exact entry you want to delete:"
    read -p "Entry to delete: " entry_to_delete

    # Display the entry and ask for confirmation
    echo "You are about to delete the following crontab entry:"
    echo "$entry_to_delete"
    read -p "Are you sure you want to delete this crontab entry? (y/n): " confirm

    if [[ $confirm == [Yy]* ]]; then
        # Proceed with deletion if confirmed
        crontab -l | grep -v "^$entry_to_delete$" | crontab -
        echo "Entry deleted."
    else
        # Abort deletion if not confirmed
        echo "Deletion aborted by user."
    fi
}


# Main menu for crontab management
while true; do
    echo "Select an option:"
    echo "1) Create or Update a Crontab"
    echo "2) List all Crontabs"
    echo "3) List the Next Crontab to Run"
    echo "4) Delete a Crontab"
    echo "5) Exit"
    read -p "Enter your choice: " choice

    case $choice in
        1)
            create_or_update_crontab
            ;;
        2)
            list_crontabs
            ;;
        3)
            list_next_crontab
            ;;
        4)
            delete_crontab
            ;;
        5)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option, please try again."
            ;;
    esac
done