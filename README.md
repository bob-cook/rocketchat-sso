# rocketchat-sso
Rocket.Chat single-signon integration with Discourse

## Rocket.Chat bot

### Permissions

- create-user
- edit-other-user-active-status
- edit-other-user-info

### Additional Permissions

- clean-channel-history
- delete-message

## Known Issues / Limitations

- logout from Rocket.Chat just returns the user back to Rocket.Chat, logged in

- updates to user metadata aren't synchronized after initial user create in Rocket.Chat 
    - usernames
    - names
    - email
    - avatars

