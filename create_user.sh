#!/bin/bash

# Define the username, the public key file and the sudoers file path
USERNAME="user"
PUB_KEY_FILE="id_rsa.pub"
SUDOERS_FILE="/etc/sudoers.d/$USERNAME"

# Check if the public key file exists in the current directory
if [ ! -f "$PUB_KEY_FILE" ]; then
    echo "Error: Public key file '$PUB_KEY_FILE' does not exist in the current directory."
    exit 1
fi

# Create the user without a home directory first to check if the user creation is successful
if ! id "$USERNAME" &>/dev/null; then
    echo "Creating user '$USERNAME'."
    useradd -m -s /bin/bash "$USERNAME"
    if [ $? -ne 0 ]; then
        echo "Failed to create user '$USERNAME'."
        exit 1
    fi
else
    echo "User '$USERNAME' already exists."
fi

# Create the .ssh directory if it doesn't exist
SSH_DIR="/home/$USERNAME/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
chown "$USERNAME":"$USERNAME" "$SSH_DIR"

# Append or create the authorized_keys file with the public key
echo "Adding public key to $USERNAME's authorized keys."
cat "$PUB_KEY_FILE" >> "$SSH_DIR/authorized_keys"
chmod 600 "$SSH_DIR/authorized_keys"
chown "$USERNAME":"$USERNAME" "$SSH_DIR/authorized_keys"

# Check if the sudoers file for the user already exists to prevent duplicates
if [ ! -f "$SUDOERS_FILE" ]; then
    echo "Adding user '$USERNAME' to the sudoers."
    echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" > "$SUDOERS_FILE"
    chmod 440 "$SUDOERS_FILE"
    echo "User '$USERNAME' can now use sudo to run any command without a password."
else
    echo "Sudoers entry for user '$USERNAME' already exists."
fi


echo "Setup completed successfully."