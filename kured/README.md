# kured

## Notes
The discord webhook is injected using an environment variable which is derived from a secret.  
See: https://containrrr.dev/shoutrrr/v0.4/services/discord/

> [!NOTE]
> The secret contents must be in this format: `token@webhookid`.  
> `discord://` is already prepended in the kured args.