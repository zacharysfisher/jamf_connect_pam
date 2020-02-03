#!/bin/bash

## Restores all System Rights to defaults from Jamf Connect
## Uses same Auth File from installation script

## NOTE ## 
# The initial pam install script needs to have run first to make backups of the authorization rules #

# Create Backup Directory if it does not exist
if [ -d "/Library/Application Support/JAMF/PAM" ] 
then
	echo "PAM Directory exists." 
else
	echo "Error: PAM Directory does not exists."
	mkdir -p /Library/Application\ Support/JAMF/PAM/backup
fi

# Checks for authorization_list
if [ -f "$authFile" ]; then
	echo "$authFile exists"
else
	echo "$authFile not found, installing..."
	$JAMF_BINARY policy -event authFile
	authorizations=$(cat "/Library/Application Support/JAMF/PAM/authorization_list.txt")
fi

# restore pam.d (remove Saml entry)
echo "Copying Sudo File"
	cp /etc/pam.d/sudo /etc/pam.d/sudo.bak
echo "Inserting new line"
	sed '/pam_saml.so/d' /etc/pam.d/sudo.bak > /etc/pam.d/sudo 
echo "Editing Permissions on new File"
	chmod 444 /etc/pam.d/sudo
	chown root:wheel /etc/pam.d/sudo
echo "Clean up .bak"
	rm -rf /etc/pam.d/sudo.bak
	
# restore pam.d (remove # lines)
echo "Copying Sudo File"
	cp /etc/pam.d/sudo /etc/pam.d/sudo.bak
echo "edit lines"
	sed 's/#auth/auth/' /etc/pam.d/sudo.bak > /etc/pam.d/sudo
echo "Editing Permissions on new File"
	chmod 444 /etc/pam.d/sudo
	chown root:wheel /etc/pam.d/sudo
echo "Clean up .bak"
	rm -rf /etc/pam.d/sudo.bak
	

# Restore Authorization Function
function restoreAuthorization {
	for authorization in $authorizations
	do
		echo "Restore default Mechanism to ${authorization}"
		echo "security authorizationdb write "${authorization}" < /Library/Application\ Support/JAMF/PAM/backup/${authorization}.bak"
	done
}

restoreAuthorization
