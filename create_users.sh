#!/bin/bash

SECURE_FOLDER="/var/secure"  # The path to the secure folder where user information will be stored
LOG_FILE="/var/log/user_management.log"  # The path to the log file for recording script execution
PASSWORD_FILE="/var/secure/user_passwords.txt"  # The path to the file where user passwords will be stored

log_message() {
    # Function to log a message with a timestamp to the log file
    # Arguments:
    #   $1: The message to be logged
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Function to generate a random password
# Note: The password will only contain alphanumeric characters and the symbols @#$% to avoid shell or system issues.
generate_password() {
    tr -dc 'A-Za-z0-9@#$%' < /dev/urandom | head -c 16
}

if [ ! -d "$SECURE_FOLDER" ]; then
    # Check if the secure folder exists, if not, create it
    mkdir -p "$SECURE_FOLDER"
    log_message "Secure folder created."
fi

# Check for command-line argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_user_file>"
    exit 1
fi

USER_FILE="$1"

# Check if file exists
if [ ! -f "$USER_FILE" ]; then
    echo "File not found: $USER_FILE"
    exit 1
fi

# Create the log file and password file if they do not exist
touch "$LOG_FILE"
touch "$PASSWORD_FILE"

# Set the permissions on the password file to be read/write only by the user executing the script
chmod 600 "$PASSWORD_FILE"

# Write the header to the password file if it is empty
if [ ! -s "$PASSWORD_FILE" ]; then
    echo "Username,Password" > "$PASSWORD_FILE"
fi

# No need to append a blank line to USER_FILE; the while loop already skips empty lines

# Read the user file line by line; each line should be in the format: username;group1,group2
while read -r line; do
    # Trim whitespace, and seperate them via ;
    username=$(echo "$line" | xargs | cut -d';' -f1)
    groups=$(echo "$line" | xargs | cut -d';' -f2)

    # Skip empty lines
    if [ -z "$username" ]; then
        continue
    fi

    # Create user group (personal group)
    if ! getent group "$username" > /dev/null; then
        groupadd "$username"
        log_message "Group '$username' created."
    else
        log_message "Group '$username' already exists."
    fi

    # Create user if not exists
    # Validate username: must be 1-32 chars, start with a letter, and contain only letters, digits, underscores, or dashes
    if [[ ! "$username" =~ ^[a-zA-Z][a-zA-Z0-9_-]{0,31}$ ]]; then
        log_message "Invalid username '$username'. Skipping user creation."
        continue
        # Generate and set password, filter out problematic characters
        password=$(generate_password | tr -d ':\n')
        echo "$username:$password" | chpasswd
        echo "$username,$password" >> "$PASSWORD_FILE"
        log_message "Password set for user '$username'."
        log_message "User '$username' created with home directory."
        # Generate and set password
        password=$(generate_password)
        echo "$username:$password" | chpasswd
        echo "$username,$password" >> "$PASSWORD_FILE"
        log_message "Password set for user '$username'."

        # Set permissions for home directory
        chmod 700 "/home/$username"
        chown "$username:$username" "/home/$username"
        log_message "Home directory permissions set for user '$username'."
    else
        log_message "User '$username' already exists."
    fi

    if [ -n "$groups" ]; then
        IFS=',' read -ra group_array <<< "$groups"
        for group in "${group_array[@]}"; do
            group=$(echo "$group" | xargs) # Trim whitespace
            if [ -n "$group" ]; then
                if ! getent group "$group" > /dev/null; then
                    groupadd "$group"
                    log_message "Group '$group' created."
                fi
                usermod -aG "$group" "$username"
                log_message "User '$username' added to group '$group'."
            fi
        done
    fi
    done
done < "${USER_FILE}"