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

## Set Keys for the PAM Module
| Key                    | Description                                                            | Example         |
|------------------------|------------------------------------------------------------------------|-----------------|
| AuthUIOIDCRedirectURI  | The Redirect URI the user is sent to after successful authentication.  | `<key>AuthUIOIDCRedirectURI</key>` `<string>https://127.0.0.1/jamfconnect</string>` |
| {{username}} | Username to authenticate to Jamf Pro with       | administrator             |
| {{password}} | Password of the user authenticating to Jamf Pro | pa$$word                  |


## Enable PAM
JAMF has good instrutions on how to enable the PAM module.  [PAM Module Documentation](https://docs.jamf.com/jamf-connect/1.4.1/administrator-guide/Pluggable_Authentication_Module_(PAM).html)

You can also follow these instructions using the nano editor.
1. Open terminal and edit the following file `sudo nano /etc/pam.d/sudo`
2. Once the editor opens, add the following to the 2nd of line of the file.  Right below `# sudo: auth account password session`: `auth sufficient pam_saml.so`
3. Press control + x to exit and then "y" and the enter key to save changes


This collection utilizes the following variables which should be defined within one of the scopes in Postman. Jamf recommends using environments instead of global or collection variables simply for the ease of use and potential for defining different Jamf Pro environments or users. Follow Postman's documentation to [Manage Environments](https://learning.getpostman.com/docs/postman/environments_and_globals/manage_environments).

| Variable     | Description                                     | Example                   |
|--------------|-------------------------------------------------|---------------------------|
| {{url}}      | Hostname and port of the Jamf Pro environment   | company.jamfcloud.com:443 |
| {{username}} | Username to authenticate to Jamf Pro with       | administrator             |
| {{password}} | Password of the user authenticating to Jamf Pro | pa$$word                  |

## Getting Started
After the collection has been imported and valid values have been defined for the variables, all calls should be supported with minimal input required. Additional data will be required either in the form of a parameter value and/or a request body.
