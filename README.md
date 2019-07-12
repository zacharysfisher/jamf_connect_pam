# jamf_connect_pam

## Overview
This page will explain how to configure Jamf Connect Login's PAM (Pluggable Authentication Module) to be used so that users can be standard users.

The PAM module is located at the following location
`/usr/local/lib/pam/pam_saml.so.2`

To use the PAM Module with Okta a few steps need to be taken.
* Create an Okta Application to handle Authentication 
* Set Keys for the PAM Module
* Enable PAM module for sudo commands
* Configure which Authentication Calls to use PAM for

    

## Create an Okta Application to handle Authentication
1. Go to the Okta Admin console and go to the Applications page.  (ie. organization.okta.com/admin/apps/active)
2. Click Add Application and click Create New App.
3. On the following Screen, select Native App as platform and OpenID Connect as Sign In Method.  Hit Create to advance to next screen.
4. On the next screen, Name your application and for login Redirect URI enter in: `https://127.0.0.1/jamfconnect` and then hit save.
5. Your app is now created.  You can assign it to users.  However, before you do so we need to configure a few more thing.  Make your App look like the following:
![OIDC App Settings](https://user-images.githubusercontent.com/17932646/61080455-18cd5100-a3f3-11e9-90fc-562d7093d1a7.png)
6. Lastly, scroll down and save the value of ClientID for use later.

## Set Keys for the PAM Module
Keys for the PAM Module get written to same plist as other Jamf Connect Login Keys: `/Library/Preferences/com.jamf.connect.login.plist`

| Key                    | Description                                                            | Example         |
|------------------------|------------------------------------------------------------------------|-----------------|
| AuthUIOIDCRedirectURI  | The Redirect URI the user is sent to after successful authentication.  | `<key>AuthUIOIDCRedirectURI</key>` `<string>https://127.0.0.1/jamfconnect</string>` |
| AuthUIOIDCProvider     | Specifies the IdP provider integrated with Jamf Connect Login          | `<key>AuthUIOIDCProvider</key>` `<string>Okta</string>` |
| AuthUIOIDCTenant       | Specifices the Tenenant or Org of your IDP Instance                    | `<key>AuthUIOIDCTenant</key>` `<string>Acme</string>` |
| AuthUIOIDCClientID     | The Client ID of the added app in your IdP used to authenticate the user | `<key>AuthUIOIDCClientID</key>` `<string>0oad0gmia54gn3y8923h1</string>` |

These keys can either be set using a Configuration Profile with JAMF Pro or by using the defaults command.

Example Defaults command: `sudo defaults write /Library/Preferences/com.jamf.connect.login.plist AuthUIOIDCProvider -string Okta`

## Enable PAM
JAMF has good instrutions on how to enable the PAM module.  [PAM Module Documentation](https://docs.jamf.com/jamf-connect/1.4.1/administrator-guide/Pluggable_Authentication_Module_(PAM).html)

You can also follow these instructions using the nano editor.
1. Open terminal and edit the following file `sudo nano /etc/pam.d/sudo`
2. Once the editor opens, add the following to the 2nd of line of the file.  Right below `# sudo: auth account password session`: `auth sufficient pam_saml.so`
3. Press control + x to exit and then "y" and the enter key to save changes

Now you can use the `sudo` command and you should be prompted for Okta login.  The next step is to configure other authentication methods to use Okta as well.

## Configure which Authentication Calls to use PAM for
To configure the PAM module to use Okta Authentication for things like unlocking System Preferences and installing software, we must use the Security Tool that ships with macOS.  The file that controls the Auth Mechanism is `com.jamf.connect.sudosaml`.  You can read this file by typing the following into terminal:
`security authorizationdb read com.jamf.connect.sudosaml`

The results shoudl look like below:

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>class</key>
	<string>evaluate-mechanisms</string>
	<key>comment</key>
	<string>Rule to allow for Azure authentication</string>
	<key>created</key>
	<real>569394749.63492501</real>
	<key>identifier</key>
	<string>authchanger</string>
	<key>mechanisms</key>
	<array>
		<string>JamfConnectLogin:AuthUINoCache</string>
	</array>
	<key>modified</key>
	<real>582579735.53209305</real>
	<key>requirement</key>
	<string>identifier authchanger and anchor apple generic and certificate leaf[subject.CN] = "Mac Developer: Joel Rennich (92Q527YFQS)" and certificate 1[field.1.2.840.113635.100.6.2.1] /* exists */</string>
	<key>shared</key>
	<true/>
	<key>tries</key>
	<integer>10000</integer>
	<key>version</key>
	<integer>1</integer>
</dict>
</plist>
```

You will notice the `mechanisms` key.  Currently, it is set to `AuthUINoCache`.  If you would like Jamf Connect to not prompt the user for authentication for as long as the Okta Token length is set, change this to `AuthUI`.
######Currently this feature does not work as intended, and JAMF has been notified.  No Estimate can be provided at this time for when it will be fixed.######

To be able to use the PAM Module for Authentication we need to do the following steps:
1. Make a backup of the sudosaml file to use to overwrite the local authentication calls
2. Determine with authorizationdb calls you want to use Jamf Connect for
3. Backup the authorizationdb file you are about to overwrite with Jamf Connect
4. Replace local authentication rule with the jamf connect rule


###Make a backup of the sudosaml file to use to overwrite the local authentication calls###
To make a backup of the sudosaml file we need to use the security tool.  First you should go to a directory that you want to work out of.  Once there, you can run this command to make a backup:
`security authorizationdb read com.jamf.connect.sudosaml > sudosaml.org`

You now have a backup of the Jamf Connect mechanism for authentication.

###Determine which authorizationdb calls you want use Jamf Connect for###
In macOS, there are many different authorization calls that are made when certain tasks are completed.  For this example, we will edit the authorization used to see if a user can install a pkg.  This authorization is `system.install.software`.  YOu can view the current rule for this call by using this command: `security authorizationdb read system.install.software`.  This default rule checks if the user is in the admin group to allow the installation of the package.

###Backup the authorizationdb file you are about to overwrite with Jamf Connect###
Now that we have determined what the authorization rule that we want to edit is we can replace the default macOS rule with the Jamf Connect one.  Before we do this, we should back up the macOS default rule in case things go wrong.  We can backup this file by typing this command: `security authorizationdb read system.isntall.software > installsoftware.org`.  

###Replace local authentication rule with Jamf Connect rule###
Now we can add our Jamf Connect rule.  We do this by using the following command: `security authorizationdb write system.install.software < sudosaml.org`.  This will overwrite the rule with the backup of the jamf connect mechanism we made of backup of earlier.  you can verify this worked by typing `security authorizationdb read system.install.software` and you should see the Jamf Connect mechanism.

Now you can test this by trying to install a package.  If everything was configured properly, you should be prompted for an Okta login when you install Packages or use the `sudo` command in terminal.


## Authorization Rules ##
| Rule Domain     | Description  |                                 
|--------------|-------------------------------------------------|---------------------------|
| system.install.software | Checks when the user is installing new software (Pkg, bundled installers   | 
| {{username}} | Username to authenticate to Jamf Pro with       |
| {{password}} | Password of the user authenticating to Jamf Pro | 
