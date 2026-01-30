# Running the Servers

## Starting Servers

### Quick Start (Interactive Console)

The recommended way to run the worldserver is with an interactive console, which lets you run commands like creating accounts:

```bash
docker exec -it peacebloom bash -c "cd /home/peacebloom/server/bin && ./worldserver"
```

This gives you the `TC>` prompt where you can type server commands directly.

### Using the Start Script

Alternatively, use the convenience script:

```bash
docker exec -it peacebloom start
```

This will:
- Start MySQL (if not running)
- Start authserver in background
- Start worldserver in foreground (interactive console)

### Background Mode

To run worldserver in the background:

```bash
start --background
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
cd /home/peacebloom/server/bin
./authserver &
```

### Start WorldServer

```bash
cd /home/peacebloom/server/bin
./worldserver
```

## Stopping Servers

### Quick Stop

```bash
stop           # Stop auth + world servers
stop --all     # Stop everything including MySQL
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

### Creating Accounts (Recommended Method)

The most reliable way to create accounts is through the **worldserver console**. With worldserver running interactively, type:

```
account create <username> <password>
account set gmlevel <username> 3 -1
```

For example, to create an admin account:
```
account create admin admin
account set gmlevel admin 3 -1
```

GM Levels:
- `0` = Player (default)
- `1` = Moderator
- `2` = GameMaster
- `3` = Administrator

> **Note:** The `-1` in the gmlevel command means "all realms".

### Default Admin Account

If setup completes successfully, it creates a default admin account:
- **Username:** `admin`
- **Password:** `admin`
- **GM Level:** 3 (Administrator)

> ⚠️ **Change this password** after your first login using the worldserver console:
> ```
> account set password admin <oldpassword> <newpassword>
> ```

### Alternative: Script-Based Account Creation

You can also try the convenience scripts, though the worldserver console method above is more reliable:

```bash
# Create a regular player account
create-gm-account myplayer mypassword

# Create a GM account
create-gm-account mygm mypassword --gm
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
