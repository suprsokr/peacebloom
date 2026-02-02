# Peacebloom

**TrinityCore + Thorium Modding Platform**

A batteries-included Docker environment for WoW Trinity Core 3.3.5 server development and modding with [the Thorium framework](https://github.com/suprsokr/thorium). Zero-config setup. Works on Linux, macOS, and Windows.

## What Peacebloom Provides

The Docker container automates the complete setup of a TrinityCore 3.3.5 development environment on Ubuntu 24.04:

1. **TrinityCore Source** - Clones and builds the TrinityCore 3.3.5 server from source
2. **Database Setup** - Downloads TDB database, initializes MySQL, creates world/characters/auth databases
3. **Game Data Extraction** - Extracts maps, DBCs, and vmaps from your WoW 3.3.5 client
4. **Thorium Workspace** - [Initializes a Thorium modding workspace](https://github.com/suprsokr/thorium/blob/main/docs/init.md)
5. **Default Admin Account** - Creates admin/admin account for immediate GM server access

The container handles all the complexity of building TrinityCore for development, setting up databases, and configuring the modding environment.

## Quick Start

```bash
# clone this repo, then:
cp .env.example .env
# Edit .env and set WOTLK_PATH to your WoW 3.3.5 client directory
docker-compose build
docker-compose up -d 
docker exec peacebloom setup -y
docker exec peacebloom start --background
```

That's it. Login as admin/admin to your dev Trinity Core 3.3.5 server.

## Modding in 30 Seconds

```bash
docker exec -it peacebloom bash
cd /thorium-workspace  # or cd ~/thorium-workspace
thorium create-mod my-mod   # Create a mod
thorium create-migration --mod my-mod adding_an_item   # Add a migration
# Edit SQL files...
thorium build && restart   # Build and restart
```

Your changes are now live. Restart your WoW client, login with admin/admin and connect to the server. Server DBCs updated, client MPQ patched, servers restarted.

## Server Administration Scripts

The `scripts/` directory provides convenient commands for managing your server. All scripts are available via `docker exec`:

```bash
# Server lifecycle
docker exec -it peacebloom start              # Start servers (interactive)
docker exec peacebloom start --background     # Start servers (background)
docker exec peacebloom stop                   # Stop servers
docker exec peacebloom restart                # Restart servers (useful after thorium build)

# Account management
docker exec peacebloom create-gm-account <user> <pass> [level]  # Create account (default GM level 3)
docker exec peacebloom change-password <user> <newpass>          # Change password

# Logs and debugging
docker exec -it peacebloom logs world         # Tail worldserver logs
docker exec -it peacebloom logs auth          # Tail authserver logs
docker exec peacebloom logs grep "error"      # Search logs

# Building
docker exec peacebloom build-tc              # Rebuild TrinityCore
```

All scripts are also available inside the container: `docker exec -it peacebloom bash`

## Documentation

| Guide | Description |
|-------|-------------|
| **[Installation](docs/INSTALL.md)** | Detailed setup, cross-platform paths, manual steps |
| **[Running Servers](docs/RUN.md)** | Start/stop, accounts, console commands |
| **[Thorium Docs](https://github.com/suprsokr/thorium/tree/main/docs)** | Modding |

## Requirements

- Docker & Docker Compose
- WoW 3.3.5 client
- 8GB RAM / 50GB disk (for building)

## License

TrinityCore: GPL-2.0 · Thorium: See [LICENSE](https://github.com/suprsokr/thorium/blob/main/LICENSE)
