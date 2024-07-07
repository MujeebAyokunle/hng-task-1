#!/bin/bash

# Paths to the log and password files in the home directory
LOG_FILE="$HOME/user_management.log"
PASSWORD_FILE="$HOME/user_passwords.txt"

# Function to log messages
log_message() {
    echo "$(date): $1" >> "$LOG_FILE"
}

# Function to generate a random password
generate_password() {
    tr -dc A-Za-z0-9 </dev/urandom | head -c 16 ; echo ''
}

# Ensure the log and password files exist
touch "$LOG_FILE"
touch "$PASSWORD_FILE"
chmod 600 "$PASSWORD_FILE"

# Check if a filename was provided
if [ -z "$1" ]; then
    echo "Usage: $0 <filename>"
    log_message "ERROR: No filename provided."
    exit 1
fi

# Read the file line by line
while IFS=';' read -r user groups; do
    # Remove whitespace
    user=$(echo "$user" | xargs)
    groups=$(echo "$groups" | xargs)

    # Skip empty lines
    if [ -z "$user" ]; then
        continue
    fi

    # Create user and personal group if they don't already exist
    if id "$user" &>/dev/null; then
        log_message "INFO: User $user already exists."
    else
        sudo useradd -m "$user"
        log_message "INFO: User $user created."
        
        # Generate a random password
        password=$(generate_password)
        
        # Set the password for the user
        echo "$user:$password" | sudo chpasswd
        
        # Store the password securely
        echo "$user,$password" >> "$PASSWORD_FILE"
        
        log_message "INFO: Password set for user $user."
    fi

    # Create personal group for user
    if ! getent group "$user" &>/dev/null; then
        sudo groupadd "$user"
        sudo usermod -aG "$user" "$user"
        log_message "INFO: Personal group $user created."
    fi

    # Add user to additional groups
    if [ -n "$groups" ]; then
        IFS=',' read -ra group_array <<< "$groups"
        for group in "${group_array[@]}"; do
            group=$(echo "$group" | xargs)
            if ! getent group "$group" &>/dev/null; then
                sudo groupadd "$group"
                log_message "INFO: Group $group created."
            fi
            sudo usermod -aG "$group" "$user"
            log_message "INFO: User $user added to group $group."
        done
    fi

done < "$1"

log_message "User creation script completed."

echo "User creation script completed. Check $LOG_FILE for details."
