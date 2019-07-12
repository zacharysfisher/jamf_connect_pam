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


## Configure which Authentication Calls to use PAM for
To configure the PAM module to use Okta Authentication, we must use the Security Tool that ships with macOS.  The file that controls the Auth Mechanism is `com.jamf.connect.sudosaml`.  You can read this file by typing the following into terminal:
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
| Variable     | Description                                     | Example                   |
|--------------|-------------------------------------------------|---------------------------|
| {{url}}      | Hostname and port of the Jamf Pro environment   | company.jamfcloud.com:443 |
| {{username}} | Username to authenticate to Jamf Pro with       | administrator             |
| {{password}} | Password of the user authenticating to Jamf Pro | pa$$word                  |

## Getting Started
After the collection has been imported and valid values have been defined for the variables, all calls should be supported with minimal input required. Additional data will be required either in the form of a parameter value and/or a request body.
