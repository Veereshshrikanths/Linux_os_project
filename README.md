
This project provides a Bash script called create_users.sh that automates the process of creating and managing user accounts in a Linux system.

It reads a text file containing usernames and group memberships, then automatically:

1.Creates users and their personal groups.

2.Adds them to additional groups.

3.Generates and stores secure random passwords.

4.Sets up home directories with proper permissions.

5.Logs all actions performed for auditing.

6.This script is useful for system administrators who need to onboard multiple users efficiently, securely, and consistently.

 How to Use It
 Installation Steps

Clone or copy the script to your Linux system:

git clone https://github.com/Veereshshrikanths/Linux_os_project.git
cd Linux_Os_projects


Make the script executable:

chmod +x create_users.sh


Prepare a user data file (for example, users.txt) with this format:

light; sudo,dev,www-data
siyoni; sudo
manoj; dev,www-data


Notes:

Each line should be in the format username;group1,group2,...

Lines starting with # will be ignored (comments).

Whitespace is automatically removed.

# Running the Script

Execute the script with superuser privileges:

sudo ./create_users.sh employees.txt

# Outputs

The script will:

Create users and groups as defined in the input file.

Generate random passwords and store them securely in:

/var/secure/user_passwords.txt


Write detailed logs to:

/var/log/user_management.log


Both files are created with strict 600 permissions (accessible only by root).

#. How It Works
 Input Parsing

Each line in the provided file is split into:

username → primary user and group name.

group list → additional groups to which the user will be added.

Lines starting with # or blank lines are ignored.

# User and Group Creation

If the group does not exist, it is created using:

groupadd <groupname>


If the user does not exist, it is created using:

useradd -m -g <groupname> -s /bin/bash <username>

# Password Generation

Each user gets a unique random 16-character password generated from /dev/urandom:

tr -dc 'A-Za-z0-9!@#$%^&*()-_' < /dev/urandom | head -c 16


The password is applied using:

echo "username:password" | chpasswd

# Secure Storage

All credentials are stored in /var/secure/user_passwords.txt.
Permissions are restricted to root using:

chmod 600 /var/secure/user_passwords.txt

# Logging

Every action (creation, update, or error) is logged with timestamps in:

/var/log/user_management.log


Example log entry:

2025-11-13 06:52:01 - User 'light' created with home directory.

#. Design Decisions

Security: Passwords are stored in a root-only file (600 permission).

Automation: The script handles user creation, password generation, and group assignment in one step.

Error Handling: Existing users or groups are skipped gracefully.

Transparency: All actions are logged for auditing and troubleshooting.

Challenges faced:

Skipping comment lines beginning with #.

Handling whitespace and malformed input lines.

Ensuring correct permissions on sensitive files.

Solutions implemented:

Input validation with xargs trimming.

Conditional checks for user/group existence.

Controlled permission settings.

# Testing
Example Input File (users.txt)
# Developer onboarding list
light; sudo,dev,www-data
siyoni; sudo
manoj; dev,www-data

Example Execution
sudo ./create_users.sh users.txt

Example Output
[INFO] Group 'light' created.
[INFO] User 'light' created with home directory.
[INFO] Password set for user 'light'.
[INFO] User 'light' added to group 'sudo'.
[INFO] User 'light' added to group 'dev'.
[INFO] User 'light' added to group 'www-data'.
[DONE] All users created successfully.

Verification Commands

Check created users:

cat /etc/passwd | grep light


Check created groups:

cat /etc/group | grep dev


View password file (root only):

sudo cat /var/secure/user_passwords.txt


View logs:

sudo less /var/log/user_management.log



# Future Improvements

Add encryption for password storage using gpg.

Include error email notifications.

Add dry-run mode for testing without making system changes.

Support user deletion and updates.


Open and read the password file from WSL (recommended; no Windows exposure):

# in your WSL terminal
sudo less /var/secure/user_passwords.csv    # view file (press q to quit)
sudo tail -n 50 /var/secure/user_passwords.csv  # last 50 lines
sudo awk -F, '$1=="light"{print $2}' /var/secure/user_passwords.csv  # extract password for user 'light'
