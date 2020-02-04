#!/bin/bash

# This version of deployment uses a plist to see which authorizations to write.  Look in this repo's directory for com.jamf.connect.pam.plist and set the ones you want to true.  This can be controlled via Config Profile in JAMF.  **Still under development/testing**

# variables
authorizations=$(cat "/Library/Application\ Support/JAMF/PAM/authorization_list.txt")
JAMF_BINARY="/usr/local/bin/jamf"
pamPath=/Library/Application\ Support/JAMF/PAM
authFile=/Library/Application\ Support/JAMF/PAM/authorization_list.txt
pamModule="/usr/local/lib/pam/pam_saml.so.2"
sudoConfig=$(cat /etc/pam.d/sudo | grep "pam_saml.so" | awk '{print $3}')

# Write Authorization Function
writeJamfAuthorization()
 {
	for authorization in $authorizations
	do
		echo "Backing up Default Authorizations"
		security authorizationdb read "${authorization}" > /Library/Application\ Support/JAMF/PAM/backup/$authorization.bak
		echo "Writing Jamf Connect Mechanism to $authorization}"
		security authorizationdb write "${authorization}" < /Library/Application\ Support/JAMF/PAM/sudosaml.org
	done
}

# Create Backup Directory if it does not exist
if [ -d "$pamPath" ] 
then
	echo "PAM Directory exists." 
else
	echo "Error: PAM Directory does not exists."
	mkdir -p /Library/Application\ Support/JAMF/PAM
fi

# Checks for authorization_list
if [ -f "$authFile" ]; then
	echo "$authFile exists"
else
	echo "$authFile not found, installing..."
	$JAMF_BINARY policy -event authFile
	authorizations=$(cat "/Library/Application Support/JAMF/PAM/authorization_list.txt")
fi

# Checks for PAM Module
if [ -f "$pamModule" ]; then
	echo "PAM Module Installed"
else
	echo "PAM Module not installed, installing..."
	$JAMF_BINARY policy -event pammodule
fi

# Rewrites Sudo Authorization
if [ $sudoConfig = "pam_saml.so" ]; then
	echo "PAM Configured"
else
	echo "Configuring PAM..."
	echo "Copying Sudo File"
	cp /etc/pam.d/sudo /etc/pam.d/sudo.bak
	echo "Inserting new line"
	sed -e '/# sudo: auth account password session/a\'$'\n''auth       required     pam_saml.so' /etc/pam.d/sudo.bak > /etc/pam.d/sudo
	sed 's/auth       required       pam_opendirectory.so/#auth      required       pam_opendirectory.so/' /etc/pam.d/sudo.bak > /etc/pam.d/sudo 
	echo "Editing Permissions on new File"
	chmod 444 /etc/pam.d/sudo
	chown root:wheel /etc/pam.d/sudo
	echo "Clean up backup file"
	rm -rf /etc/pam.d/sudo.bak
	echo "Copying Sudo File"
	cp /etc/pam.d/sudo /etc/pam.d/sudo.bak
	echo "Remove local auth"
	sed 's/auth       required       pam_opendirectory.so/#auth      required       pam_opendirectory.so/' /etc/pam.d/sudo.bak > /etc/pam.d/sudo 
	echo "Editing Permissions on new File"
	chmod 444 /etc/pam.d/sudo
	chown root:wheel /etc/pam.d/sudo
	echo "Clean up backup file"
	rm -rf /etc/pam.d/sudo.bak
fi

# Create Backup of Jamf Connect Mechanism / remove NoCache
echo "Creating Backup of JamfConnect Mech - Removing NoCache"
security authorizationdb read com.jamf.connect.sudosaml > /Library/Application\ Support/JAMF/PAM/sudosaml.org
sed -i -e 's/AuthUINoCache/AuthUI/g' /Library/Application\ Support/JAMF/PAM/sudosaml.org

# Write new Mechanism to jamf connect
echo "Write new Mech to Jamf Folder"
security authorizationdb read com.jamf.connect.sudosaml < /Library/Application\ Support/JAMF/PAM/sudosaml.org

echo "Function"
writeJamfAuthorization
