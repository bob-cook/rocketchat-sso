# rocketchat-sso
Rocket.Chat single-signon integration with Discourse

Allow your Discourse users access to a Rocket.Chat instance usign their same identity, avatar, etc. A toolbar icon provides easy access to open a new browser tab to the chat system.

## Discourse Configuration

### Install the plugin

Add this plug-in using the normal plug-in configuration method in your app.yaml file. The git URL is https://github.com/bob-cook/rocketchat-sso.git

### Rocket.Chat MongoDB Access

You will need to allow access to the Rocket.Chat MongoDB instance. The simplest way to do this is to put your Discourse Docker instance on the same virtual network as your Rocket.Chat Docker instance. Then configure the MongoDB address and port in the plug-in admin page.

## Rocket.Chat Configuration

### Dedicated API User
Create a user which will be the dedicated "bot" for the Discourse plug-in to coordinate changes with your Rocket.Chat instance.

This user will need to have the following permissions configured:

- create-user
- edit-other-user-active-status
- edit-other-user-info

Give the user a strong password then configure the username and password in the plug-in admin page.

### Iframe configuration
Enable the Iframe configuration in the Accounts section with the following information:

- Iframe URL should be set to the URL of your Discourse instance
- API URL should be set to the URL of your Discourse instance plus /rocketchat-sso/auth e.g. _https://chat.example.com/rocketchat-sso/auth_

## Known Issues / Limitations
Despite the many features already implemented, there are a few limitations.

- logout from Rocket.Chat just returns the user back to Rocket.Chat, logged in (as long as they are still logged into Discourse)

- updates to user metadata aren't synchronized after initial user creation in Rocket.Chat 
    - usernames
    - names
    - email
    - avatars

