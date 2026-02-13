# Maestral Dropbox Headless Setup Guide

If maestral ever refuses to connect with the existing secret in secrets/maestral.age,
you will have to go through this process.
It should work easily, but since you're gonna remove the existing config, maybe 
don't do it lightly. Maybe even back the config up instead, dunno.

One of the main reasons this might happen is because you ran 
`maestral auth unlink (NEVER DO THIS)`: it revokes the token that all machines use. 

## Initial Browser Login (One-Time)

You need the refresh-token, because (unlike the access token), it doesn't expire 
(unless you revoke through Dropbox or unlink with maestral)

So connect maestral once, to fetch the refresh-token it has stored.

Assuming maestral is already installed, (and maybe even running)

1. Install/run Maestral:
   ```
   systemctl --user stop maestral
   maestral stop
   rm -rf ~/.config/maestral
   maestral auth link
   ```
   - Choose "Print auth URL".
   - Open URL, authorize Dropbox.
   - Paste auth code → ✓ "Credentials written".

2. **Immediately extract refresh token into a variable**:
   ```
   token=$(kwallet-query -r "$(kwallet-query -l -f Maestral kdewallet)" -f Maestral kdewallet)
   ```
   Don't close this terminal - we're gonna validate the token and then encrypt it.

## Validate Token (Manual Test)

```
rm -rf ~/.config/maestral
maestral auth link --refresh-token="$token"  # ✓ Credentials written
maestral config set path "/home/tvollert/Dropbox"
mkdir -p ~/Dropbox
maestral start  # ✓ Starting Maestral... [OK]
maestral status  # Account: yourname@me.com
maestral stop
rm -rf ~/.config/maestral
```

## Agenix Secret Update

Copy the token to your clipboard (maybe after `echo $token`) and edit from within ./secrets:

```
cd secrets
agenix -e maestral.age
```

`secrets/maestral.age`:
```
MAESTRAL_REFRESH_TOKEN=<token>
```

**Redeploy**:

Rebuild/switch as usual, then

```
systemctl --user restart maestral
maestral status  # Verify
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| "Revoked" | Token invalidated (unlink/browser relink → re-extract (start from top)). |
| No `/run/secrets/maestral` | Check `secrets.nix` - is the entry gone? |
| "Paused" | `maestral resume`. |
| Daemon crashes | Logs: `journalctl --user -u maestral`. |
