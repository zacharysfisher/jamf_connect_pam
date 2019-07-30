#!/bin/bash


# variables
authorizations=$(cat "/Users/zachary.fisherintersection.com/Dropbox (Control Group)/IXN_Mac_Admin/Jamf Connect/authorization_list.txt")
JAMF_BINARY="/usr/local/bin/jamf"
pamPath=/Library/Application\ Support/JAMF/PAM
authFile=/Library/Application\ Support/JAMF/PAM/authorization_list.txt

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

# Create Backup of Jamf Connect Mechanism
security authorizationdb read com.jamf.connect.sudosaml > /Library/Application\ Support/JAMF/PAM/sudosaml.org

# Write Authorization Function
function writeJamfAuthorization {
	for authorization in $authorizations
	do
		echo "Backing up Default Authorizations"
		security authorizationdb read "${authorization}" > /Library/Application\ Support/JAMF/PAM/$authorization.bak
		echo "Check Plist for Write Value"
		authorizationValue=$(defaults read "/Users/zachary.fisherintersection.com/Dropbox (Control Group)/IXN_Mac_Admin/Jamf Connect/com.jamf.connect.pam.plist" $authorization)
		if [[ $authorizationValue = 1 ]]; then
			echo "Writing Jamf Connect Mechanism to $authorization}"
			echo "security authorizationdb write "${authorization}" < /Library/Application\ Support/JAMF/PAM/sudosaml.org"
		else
			echo "Passing Authorization Rewrite"
		fi
	done
}





#for authorization in $authorizations
#do
#    echo "Backuping up Authorizations"
#	security authorizationdb read "${authorization}" > /Library/Application\ Support/JAMF/PAM/$authorization.bak
#	echo "security authorizationdb write "${authorization}" < /Library/Application\ Support/JAMF/PAM/sudosaml.org"
#done

