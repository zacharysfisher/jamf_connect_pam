#!/bin/bash

# This deployment will automatically write all authorizations and make backups.  This is not controlled via a plist or configuration profile.

# variables
authorizations=$(cat "/Library/Application Support/JAMF/PAM/authorization_list.txt")
JAMF_BINARY="/usr/local/bin/jamf"
pamPath=/Library/Application\ Support/JAMF/PAM
authFile=/Library/Application\ Support/JAMF/PAM/authorization_list.txt
pamModule=/usr/local/lib/pam/pam_saml.so.2
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
	echo "Creating Directory"
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

# Checks for PAM Module
if [ -f "$pamModule" ]; then
	echo "PAM Module Installed"
else
	echo "PAM Module not installed, installing..."
	$JAMF_BINARY policy -event "Jamf Connect Login-enrollment"
	/usr/local/bin/authchanger -reset -Okta -DefaultJCRight
fi

# Rewrites Sudo Authorization / Remove Local Auth
if [ $sudoConfig = "pam_saml.so" ]; then
	echo "PAM Configured"
else
	echo "Configuring PAM..."
	echo "Copying Sudo File"
	cp /etc/pam.d/sudo /etc/pam.d/sudo.bak
	echo "Inserting new line"
	sed -e '/# sudo: auth account password session/a\'$'\n''auth       required       pam_saml.so' /etc/pam.d/sudo.bak > /etc/pam.d/sudo 
	echo "Editing Permissions on new File"
	chmod 444 /etc/pam.d/sudo
	chown root:wheel /etc/pam.d/sudo
	echo "Clean up backup file"
	rm -rf /etc/pam.d/sudo.bak
	# Disable Local Auth
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

echo "Authorization Function"
writeJamfAuthorization


# Writes System Install Software Mech to allow Root
echo '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs$
<plist version="1.0">
<dict>
	<key>allow-root</key>
	<true/>
	<key>class</key>
	<string>user</string>
	<key>comment</key>
	<string>Rule to allow for Azure authentication</string>
	<key>created</key>
	<real>623683870.02615499</real>
	<key>identifier</key>
	<string>authchanger</string>
	<key>mechanisms</key>
	<array>
		<string>JamfConnectLogin:AuthUINoCache</string>
	</array>
	<key>modified</key>
	<real>623683870.02615499</real>
	<key>requirement</key>
	<string>anchor apple generic and identifier authchanger and (certificat$
	<key>shared</key>
	<true/>
	<key>tries</key>
	<integer>10000</integer>
	<key>version</key>
	<integer>1</integer>
</dict>
</plist>' >> /Library/Application\ Support/JAMF/PAM/backup/system.install.software.bak

security authorizationdb write system.install.software < /Library/Application\ Support/JAMF/PAM/backup/system.install.software.bak
security authorizationdb write system.install.apple-software < /Library/Application\ Support/JAMF/PAM/backup/system.install.software.bak