# Running the Servers

## Starting Servers

### Quick Start

```bash
docker exec -it trinitycore ./scripts/start-servers.sh
```

This will:
- Start MySQL (if not running)
- Start authserver in background
- Start worldserver in foreground (interactive console)

### Background Mode

To run worldserver in the background:

```bash
./scripts/start-servers.sh --background
```

Logs will be written to:
- `/tmp/authserver.log`
- `/tmp/worldserver.log`

View logs:
```bash
tail -f /tmp/worldserver.log
```

## Manual Server Control

### Start MySQL

```bash
sudo service mysql start
```

### Start AuthServer

```bash
cd /home/trinitycore/server/bin
./authserver &
```

### Start WorldServer

```bash
cd /home/trinitycore/server/bin
./worldserver
```

## Stopping Servers

### Quick Stop

```bash
./scripts/stop-servers.sh           # Stop auth + world servers
./scripts/stop-servers.sh --all     # Stop everything including MySQL
```

Options:
- `--world-only` - Stop only worldserver
- `--auth-only` - Stop only authserver  
- `--mysql` - Also stop MySQL
- `--all` - Stop everything

### Manual Stop

**WorldServer:** If running in foreground: `Ctrl+C`

If running in background:
```bash
pkill -f worldserver
```

**AuthServer:**
```bash
pkill -f authserver
```

**MySQL:**
```bash
sudo service mysql stop
```

### Stop Container

```bash
# From host
docker-compose down
```

## Accounts

### Default Admin Account

Setup automatically creates a default admin account:
- **Username:** `admin`
- **Password:** `admin`
- **GM Level:** 3 (Administrator)

> ⚠️ **Change this password** after your first login:
> ```bash
> ./scripts/change-password.sh admin yournewpassword
> ```

### Creating Additional Accounts

Use the `create-account.sh` script (no server restart needed):

```bash
# Create a regular player account
./scripts/create-account.sh myplayer mypassword

# Create a GM account
./scripts/create-account.sh mygm mypassword --gm

# Create account with specific GM level (0-3)
./scripts/create-account.sh mymod mypassword --gmlevel 1
```

GM Levels:
- `0` = Player (default)
- `1` = Moderator
- `2` = GameMaster
- `3` = Administrator

### Changing Passwords

```bash
./scripts/change-password.sh <username> <new_password>
```

Changes take effect immediately—no server restart needed.

### Using Worldserver Console

You can also create accounts via the worldserver console:

```
account create <username> <password>
account set gmlevel <username> 3 -1
```

## Connecting to the Server

1. Edit your WoW client's `realmlist.wtf`:
   ```
   set realmlist 127.0.0.1
   ```

2. Launch WoW client

3. Login with the account you created

## Ports

- `3306` - MySQL
- `3724` - AuthServer
- `8085` - WorldServer

## Server Console Commands

Common commands:
- `server info` - Server information
- `account create <user> <pass>` - Create account
- `account set gmlevel <user> <level>` - Set GM level
- `reload all` - Reload all configs
- `.help` - List available commands

See TrinityCore documentation for full command list.
