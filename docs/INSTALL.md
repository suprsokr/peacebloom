# Installation

Complete guide for setting up Peacebloom - the TrinityCore + Thorium modding platform.

## Prerequisites

- **Docker** and **Docker Compose** (Docker Desktop recommended)
- **WoW 3.3.5 Client** - Required for map/DBC extraction
- **8GB+ RAM** - Recommended for building TrinityCore
- **50GB+ Disk Space** - For source, builds, and extracted data

## Quick Start (Automated)

```bash
# 1. Copy environment file and configure your WoW client path
cp .env.example .env
# Edit .env and set WOTLK_PATH to your WoW 3.3.5 client directory

# 2. Build and start Docker
docker-compose build
docker-compose up -d

# 3. Run automated setup (clones source, downloads TDB, builds, configures)
docker exec -it peacebloom setup

# 4. Start servers
docker exec -it peacebloom start
```

The `setup` script will automatically:
- Clone TrinityCore 3.3.5 source (if not present)
- Download the latest TDB world database (if not present)
- Build TrinityCore binaries
- Initialize MySQL and import databases
- Extract maps/vmaps from your WoW client
- Build and install Thorium CLI
- Create a default admin account (`admin` / `admin` with GM level 3)

For fully non-interactive setup (auto-accepts all prompts):
```bash
docker exec -it peacebloom setup -y
```

---

## Step-by-Step Installation (Manual)

If you prefer more control, follow these detailed steps.

### 1. Clone TrinityCore Source (Optional)

You can clone manually or let `setup` do it automatically:

```bash
git clone -b 3.3.5 https://github.com/TrinityCore/TrinityCore.git tc-source
```

### 2. Configure Environment

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` and set your WoW client path.

#### Cross-Platform Path Examples

Docker Desktop handles path translation automatically on all platforms. Use your native path format:

| Platform | Example Path |
|----------|--------------|
| **Linux** | `/home/username/games/wotlk` |
| **macOS** | `/Users/username/Games/wotlk` |
| **Windows** | `C:\Games\WoW335` or `C:/Games/WoW335` |
| **WSL2** | `/mnt/c/Games/WoW335` or `/home/username/games/wotlk` |

Example `.env` configurations:

```bash
# Linux
WOTLK_PATH=/home/username/games/wotlk

# macOS
WOTLK_PATH=/Users/username/Games/wotlk

# Windows (native path - both formats work)
WOTLK_PATH=C:\Games\WoW335
WOTLK_PATH=C:/Games/WoW335

# WSL2 (accessing Windows drive)
WOTLK_PATH=/mnt/c/Games/WoW335
```

> **WSL2 Performance Tip:** For best I/O performance, store files in the Linux filesystem (`/home/...`) rather than the Windows filesystem (`/mnt/c/...`).

### 3. Build and Start Docker

```bash
# Build the Docker image (first time takes a few minutes)
docker-compose build

# Start the container in background
docker-compose up -d
```

### 4. Build TrinityCore

```bash
docker exec -it peacebloom build-tc
```

This takes 10-30 minutes depending on your hardware. It will:
- Configure CMake with debug flags
- Compile TrinityCore binaries
- Install to `/home/peacebloom/server/bin/`
- Copy default configuration files

### 5. Run Setup

```bash
docker exec -it peacebloom setup
```

This will:
- Clone TrinityCore source (if not present)
- Download TDB database (if not present)
- Build TrinityCore (if not already built)
- Initialize MySQL 8 and create databases (auth, characters, world, dbc)
- Import base database schemas
- Configure realmlist for localhost
- Extract maps/vmaps/dbc from WoW client
- Create a default admin account (`admin` / `admin` with GM level 3)

### 6. Start Servers

```bash
docker exec -it peacebloom start
```

This starts:
- MySQL (if not running)
- AuthServer (background)
- WorldServer (foreground with console)

See [RUN.md](RUN.md) for more server management options.

## Directory Structure

```
├── tc-source/           # TrinityCore source (cloned by setup)
├── thorium-workspace/   # Thorium workspace
├── scripts/             # Container scripts
├── Dockerfile           # Container definition
├── docker-compose.yml   # Docker services
└── docs/                # Documentation
```

## Docker Volumes

| Volume/Mount | Container Path | Purpose |
|--------------|----------------|---------|
| `server` | `/home/peacebloom/server` | Binaries, configs, maps, TDB |
| `mysql_data` | `/var/lib/mysql` | MySQL database files |
| `./thorium-workspace` | `/home/peacebloom/thorium-workspace` | Thorium workspace |
| `./tc-source` | `/home/peacebloom/TrinityCore` | TC source |
| `./scripts` | `/home/peacebloom/scripts` | Container scripts |
| `${WOTLK_PATH}` | `/wotlk` | WoW 3.3.5 client |

## Database Access

The setup creates these MySQL users:

| User | Password | Access |
|------|----------|--------|
| `root` | (none, socket auth) | All databases |
| `trinity` | `trinity` | auth, characters, world, dbc |

Connect from host:
```bash
mysql -h 127.0.0.1 -P 3306 -u trinity -ptrinity world
```

Connect from container:
```bash
sudo mysql world
```

## Using Thorium

After setup, Thorium is ready to use:

```bash
# Enter container
docker exec -it peacebloom bash

# Go to thorium workspace
cd /thorium-workspace  # or cd ~/thorium-workspace

# Check Thorium is installed
thorium version

# Create your first mod
thorium create-mod my-first-mod

# Full build (apply migrations, export DBCs, package MPQs)
thorium build
```

See [thorium/README.md](https://github.com/suprsokr/thorium/docs) for complete documentation.
