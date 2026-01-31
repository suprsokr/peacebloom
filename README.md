# Peacebloom

**TrinityCore + Thorium Modding Platform**

A batteries-included Docker environment for WoW Trinity Core 3.3.5 server development and modding with [the Thorium framework](https://github.com/suprsokr/thorium). Zero-config setup. Works on Linux, macOS, and Windows.

## Quick Start

```bash
cp .env.example .env           # Copy environment template
# Edit .env and set WOTLK_PATH to your WoW 3.3.5 client directory
docker-compose up -d           # Build and start container
docker exec -it peacebloom setup   # Automated setup
docker exec -it peacebloom start   # Start servers
```

That's it. Login as admin/admin to your dev Trinity Core 3.3.5 server.

## Modding in 30 Seconds

```bash
docker exec -it peacebloom bash
cd mods
thorium create-mod my-mod   # Create a mod
thorium create-migration --mod my-mod adding_an_item   # Add a migration
# Edit SQL files...
thorium build && restart   # Build and restart
```

Your changes are now live. Restart your WoW client, login with admin/admin and connect to the server. Server DBCs updated, client MPQ patched, servers restarted.

## Documentation

| Guide | Description |
|-------|-------------|
| **[Installation](docs/INSTALL.md)** | Detailed setup, cross-platform paths, manual steps |
| **[Running Servers](docs/RUN.md)** | Start/stop, accounts, console commands |
| **[Thorium Docs](https://github.com/suprsokr/thorium/tree/main/docs)** | DBC editing, SQL migrations, LuaXML, MPQ packaging |

## Requirements

- Docker & Docker Compose
- WoW 3.3.5 client
- 8GB RAM / 50GB disk (for building)

## License

TrinityCore: GPL-2.0 · Thorium: See [LICENSE](https://github.com/suprsokr/thorium/blob/main/LICENSE)
