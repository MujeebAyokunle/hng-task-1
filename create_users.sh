#!/bin/bash

# Paths to the log and password files
LOG_DIR="/var/log"
LOG_FILE="$LOG_DIR/user_management.log"
SECURE_DIR="/var/secure"
PASSWORD_FILE="$SECURE_DIR/user_passwords.txt"

# Function to log messages
log_message() {
    echo "$(date): $1" >> "$LOG_FILE"
}

# Function to generate a random password
generate_password() {
    tr -dc A-Za-z0-9 </dev/urandom | head -c 16 ; echo ''
}

# Ensure secure directory exists and has the correct permissions
if [ ! -d "$SECURE_DIR" ]; then
    sudo mkdir -p "$SECURE_DIR"
    sudo chmod 700 "$SECURE_DIR"
    sudo chown root:root "$SECURE_DIR"
    log_message "INFO: Created and secured directory $SECURE_DIR."
else
    sudo chmod 700 "$SECURE_DIR"
    sudo chown root:root "$SECURE_DIR"
    log_message "INFO: Verified and secured directory $SECURE_DIR."
fi

# Ensure log directory exists and has the correct permissions
if [ ! -d "$LOG_DIR" ]; then
    sudo mkdir -p "$LOG_DIR"
    sudo chmod 755 "$LOG_DIR"
    sudo chown root:root "$LOG_DIR"
    log_message "INFO: Created and secured directory $LOG_DIR."
fi

# Ensure log file exists and has the correct permissions
if [ ! -f "$LOG_FILE" ]; then
    sudo touch "$LOG_FILE"
    sudo chmod 644 "$LOG_FILE"
    sudo chown root:root "$LOG_FILE"
    log_message "INFO: Created and secured log file $LOG_FILE."
else
    sudo chmod 644 "$LOG_FILE"
    sudo chown root:root "$LOG_FILE"
    log_message "INFO: Verified and secured log file $LOG_FILE."
fi

# Ensure password file exists and has the correct permissions
if [ ! -f "$PASSWORD_FILE" ]; then
    sudo touch "$PASSWORD_FILE"
    sudo chmod 600 "$PASSWORD_FILE"
    sudo chown root:root "$PASSWORD_FILE"
    log_message "INFO: Created and secured password file $PASSWORD_FILE."
else
    sudo chmod 600 "$PASSWORD_FILE"
    sudo chown root:root "$PASSWORD_FILE"
    log_message "INFO: Verified and secured password file $PASSWORD_FILE."
fi

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
        echo "$user,$password" | sudo tee -a "$PASSWORD_FILE" > /dev/null
        
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
