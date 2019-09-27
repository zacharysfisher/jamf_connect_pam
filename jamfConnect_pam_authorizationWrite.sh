#!/bin/bash


# variables
authorizations=$(cat "/Library/Application\ Support/JAMF/PAM/authorization_list.txt")
JAMF_BINARY="/usr/local/bin/jamf"
pamPath=/Library/Application\ Support/JAMF/PAM
authFile=/Library/Application\ Support/JAMF/PAM/authorization_list.txt
prefsTool=/Users/Shared/prefs.py
pamModule="/usr/local/lib/pam/pam_saml.so.2"
sudoConfig=$(cat /etc/pam.d/sudo | grep "pam_saml.so" | awk '{print $3}')

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
fi


# Checks for Prefs Tool
if [ -f "$prefsTool" ]; then
	echo "Prefs Tool exists"
else
	echo "Prefs Tool not found, installing..."
	$JAMF_BINARY policy -event prefsTool
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
	sed -e '/# sudo: auth account password session/a\'$'\n''auth       sufficient     pam_saml.so' /etc/pam.d/sudo.bak > /etc/pam.d/sudo
	echo "Editing Permissions on new File"
	chmod 444 /etc/pam.d/sudo
	chown root:wheel /etc/pam.d/sudo
fi

# Create Backup of Jamf Connect Mechanism
security authorizationdb read com.jamf.connect.sudosaml > /Library/Application\ Support/JAMF/PAM/sudosaml.org

# Write Authorization Function
function writeJamfAuthorization {
	for authorization in $authorizations
	do
		echo "Backing up Default Authorizations"
		security authorizationdb read "${authorization}" > /Library/Application\ Support/JAMF/PAM/$authorization.bak
		echo "Check Plist for Write Value"
		authorizationValue=$(python /Users/Shared/prefs.py com.jamf.connect.pam "${authorization}" | awk '{print $3}')
		if [[ $authorizationValue = "True" ]]; then
			echo "Writing Jamf Connect Mechanism to $authorization}"
			echo "security authorizationdb write "${authorization}" < /Library/Application\ Support/JAMF/PAM/sudosaml.org"
		else
			echo "Passing Authorization Rewrite"
		fi
	done
}

writeJamfAuthorization
