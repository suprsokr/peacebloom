#!/bin/bash
# TrinityCore + Thorium setup script - run this inside the container
#
# Usage: ./setup.sh [-y]
#   -y    Non-interactive mode (auto-accept all prompts)

set -e

# Parse command line arguments
AUTO_YES=false
while getopts "y" opt; do
    case $opt in
        y) AUTO_YES=true ;;
        *) echo "Usage: $0 [-y]"; exit 1 ;;
    esac
done

# Helper function for prompts
prompt_yes_no() {
    local prompt="$1"
    if [ "$AUTO_YES" = true ]; then
        echo "$prompt (auto-yes)"
        return 0
    fi
    read -p "$prompt (y/n) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

echo "=== TrinityCore 3.3.5 + Thorium Setup ==="

# =============================================================================
# Step 1: Check/Clone TrinityCore Source
# =============================================================================
TC_DIR="/home/trinitycore/TrinityCore"

if [ ! -f "$TC_DIR/CMakeLists.txt" ]; then
    echo ""
    echo "TrinityCore source not found at $TC_DIR"
    echo "This is required to build the server."
    echo ""
    if prompt_yes_no "Clone TrinityCore 3.3.5 source now?"; then
        echo "Cloning TrinityCore 3.3.5 branch..."
        # Clone into a temp directory first, then move contents
        # (because the mount point directory already exists)
        git clone -b 3.3.5 --depth 1 https://github.com/TrinityCore/TrinityCore.git /tmp/tc-source
        cp -r /tmp/tc-source/. "$TC_DIR/"
        rm -rf /tmp/tc-source
        echo "TrinityCore source cloned successfully!"
    else
        echo "Skipping source clone. Please clone TrinityCore manually:"
        echo "  git clone -b 3.3.5 https://github.com/TrinityCore/TrinityCore.git tc-source"
        exit 1
    fi
fi

# =============================================================================
# Step 2: Check/Download TDB Database
# =============================================================================
DATA_DIR="/home/trinitycore/server/data"
TDB_FILE=$(ls "$DATA_DIR"/TDB_full_world_335*.sql 2>/dev/null | head -1)

if [ -z "$TDB_FILE" ]; then
    echo ""
    echo "TDB world database file not found in $DATA_DIR"
    echo "This is required to populate the world database."
    echo ""
    if prompt_yes_no "Download latest TDB database from GitHub?"; then
        echo "Fetching latest TDB release info from GitHub..."
        
        # Get the latest release info for TrinityCore 3.3.5 branch
        RELEASE_INFO=$(curl -s "https://api.github.com/repos/TrinityCore/TrinityCore/releases" | \
            grep -E '"tag_name"|"browser_download_url".*TDB_full_world_335.*\.sql\.7z' | head -4)
        
        # Extract download URL for TDB file
        DOWNLOAD_URL=$(echo "$RELEASE_INFO" | grep "browser_download_url" | head -1 | sed 's/.*"\(https[^"]*\)".*/\1/')
        
        if [ -z "$DOWNLOAD_URL" ]; then
            echo "Could not find TDB download URL from GitHub releases."
            echo "Please download manually from:"
            echo "  https://github.com/TrinityCore/TrinityCore/releases"
            echo "Look for TDB_full_world_335.*.7z and extract the .sql file to data/"
        else
            FILENAME=$(basename "$DOWNLOAD_URL")
            echo "Downloading: $FILENAME"
            curl -L -o "/tmp/$FILENAME" "$DOWNLOAD_URL"
            
            echo "Extracting..."
            cd "$DATA_DIR"
            
            # Check if 7z or p7zip is available
            if command -v 7z &> /dev/null; then
                7z x "/tmp/$FILENAME" -o"$DATA_DIR" -y
            elif command -v 7zr &> /dev/null; then
                7zr x "/tmp/$FILENAME" -o"$DATA_DIR" -y
            else
                # Try to install p7zip-full
                echo "Installing p7zip for extraction..."
                sudo apt-get update && sudo apt-get install -y p7zip-full
                7z x "/tmp/$FILENAME" -o"$DATA_DIR" -y
            fi
            
            rm -f "/tmp/$FILENAME"
            
            # Verify extraction
            TDB_FILE=$(ls "$DATA_DIR"/TDB_full_world_335*.sql 2>/dev/null | head -1)
            if [ -n "$TDB_FILE" ]; then
                echo "TDB database downloaded and extracted: $(basename "$TDB_FILE")"
            else
                echo "Warning: Extraction may have failed. Please check $DATA_DIR"
            fi
        fi
    else
        echo "Skipping TDB download. Please download manually from:"
        echo "  https://github.com/TrinityCore/TrinityCore/releases"
        echo "Extract the .sql file to: $DATA_DIR/"
    fi
fi

# =============================================================================
# Step 3: Build TrinityCore (if needed)
# =============================================================================
if [ ! -f /home/trinitycore/server/bin/worldserver ]; then
    echo ""
    echo "TrinityCore binaries not found!"
    echo ""
    if prompt_yes_no "Build TrinityCore now?"; then
        /home/trinitycore/scripts/build-tc.sh
    else
        echo "Skipping build. You can run ./scripts/build-tc.sh later."
        exit 1
    fi
fi

# Check if MySQL is already initialized
if [ -d /var/lib/mysql/mysql ]; then
    echo "MySQL already initialized, skipping initialization."
elif [ -z "$(ls -A /var/lib/mysql 2>/dev/null)" ]; then
    echo "Initializing MySQL..."
    sudo chown -R mysql:mysql /var/lib/mysql
    sudo mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql 2>&1 || true
    sudo chown -R mysql:mysql /var/lib/mysql
else
    echo "MySQL data directory exists but mysql database not found. Starting MySQL anyway..."
fi

# Start MySQL
echo "Starting MySQL..."
sudo chown -R mysql:mysql /var/lib/mysql
sudo service mysql stop 2>/dev/null || true
sudo service mysql start
sleep 8

# Wait for MySQL to be ready
echo "Waiting for MySQL to be ready..."
for i in {1..30}; do
    if sudo mysql -e "SELECT 1" >/dev/null 2>&1; then
        echo "MySQL is ready!"
        break
    fi
    echo "Attempt $i/30: Waiting for MySQL..."
    sleep 2
done

# Verify MySQL is accessible
if ! sudo mysql -e "SELECT 1" >/dev/null 2>&1; then
    echo "ERROR: Cannot connect to MySQL after 60 seconds. Check MySQL logs:"
    echo "  sudo tail -50 /var/log/mysql/error.log"
    exit 1
fi

# Create TrinityCore databases
echo "Creating TrinityCore databases..."
sudo mysql < /home/trinitycore/TrinityCore/sql/create/create_mysql.sql

# Import base database schemas
echo "Importing base database schemas..."
sudo mysql auth < /home/trinitycore/TrinityCore/sql/base/auth_database.sql
sudo mysql characters < /home/trinitycore/TrinityCore/sql/base/characters_database.sql

# Setup realmlist
echo "Configuring realmlist..."
sudo mysql auth -e "INSERT INTO realmlist (name, address, port, icon, flag, gamebuild) VALUES ('Trinity', '127.0.0.1', 8085, 0, 0, 12340) ON DUPLICATE KEY UPDATE address='127.0.0.1', port=8085;"

# Copy TDB file if available
TDB_FILE=$(ls /home/trinitycore/server/data/TDB_*.sql 2>/dev/null | head -1)
if [ -n "$TDB_FILE" ]; then
    echo "Copying TDB file: $(basename $TDB_FILE)"
    cp "$TDB_FILE" /home/trinitycore/server/bin/
fi

# Extract maps if WoW client is mounted and not already extracted
if [ -d /wotlk/Data ]; then
    cd /home/trinitycore/server/bin
    
    if [ ! -d "maps" ] || [ -z "$(ls -A maps 2>/dev/null)" ]; then
        echo "Extracting game data from WoW client..."
        
        echo "Extracting maps and DBCs..."
        ./mapextractor -i /wotlk -f 0
        
        echo "Extracting vmaps..."
        ./vmap4extractor -d /wotlk
        
        echo "Assembling vmaps..."
        mkdir -p vmaps
        ./vmap4assembler Buildings vmaps
        
        echo "Game data extraction complete!"
    else
        echo "Maps already extracted, skipping extraction."
    fi
else
    echo "Warning: /wotlk not mounted. Skipping game data extraction."
    echo "Mount your WoW 3.3.5 client directory to extract maps."
fi

# Setup Thorium modding framework
echo ""
echo "=== Setting up Thorium Modding Framework ==="

if [ -d /home/trinitycore/thorium ]; then
    # Build Thorium CLI if not already built
    if ! command -v thorium &> /dev/null; then
        echo "Building Thorium CLI..."
        /home/trinitycore/scripts/build-thorium.sh
    else
        echo "Thorium CLI already installed: $(thorium version)"
    fi
    
    # Create DBC database for Thorium
    echo "Creating Thorium DBC database..."
    sudo mysql -e "CREATE DATABASE IF NOT EXISTS dbc CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    
    # Grant permissions to root (used by Thorium with socket auth)
    sudo mysql -e "GRANT ALL PRIVILEGES ON dbc.* TO 'root'@'localhost';"
    
    # Create trinity user for world database access (matches mods/config.json)
    echo "Creating trinity database user..."
    sudo mysql -e "CREATE USER IF NOT EXISTS 'trinity'@'localhost' IDENTIFIED BY 'trinity';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON world.* TO 'trinity'@'localhost';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON auth.* TO 'trinity'@'localhost';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON characters.* TO 'trinity'@'localhost';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON dbc.* TO 'trinity'@'localhost';"
    
    # Also allow connections from docker host (for external tools)
    sudo mysql -e "CREATE USER IF NOT EXISTS 'trinity'@'%' IDENTIFIED BY 'trinity';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON world.* TO 'trinity'@'%';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON auth.* TO 'trinity'@'%';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON characters.* TO 'trinity'@'%';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON dbc.* TO 'trinity'@'%';"
    
    sudo mysql -e "FLUSH PRIVILEGES;"
    
    echo "Thorium setup complete!"
else
    echo "Note: Thorium source not found at /home/trinitycore/thorium"
    echo "The thorium/ directory should be mounted via docker-compose.yml"
fi

# =============================================================================
# Step 8: Create Default Admin Account
# =============================================================================
echo ""
echo "=== Creating Default Admin Account ==="

# Check if any accounts exist
ACCOUNT_COUNT=$(sudo mysql -N -e "SELECT COUNT(*) FROM auth.account;" 2>/dev/null || echo "0")

if [ "$ACCOUNT_COUNT" = "0" ]; then
    echo "No accounts found. Creating default admin account..."
    /home/trinitycore/scripts/create-account.sh admin admin --gm
    echo ""
    echo "Default admin account created!"
    echo "  Username: admin"
    echo "  Password: admin"
    echo "  GM Level: 3 (Administrator)"
    echo ""
    echo "IMPORTANT: Change this password after first login!"
else
    echo "Accounts already exist ($ACCOUNT_COUNT found). Skipping default account creation."
    echo "To create additional accounts, use:"
    echo "  ./scripts/create-account.sh <username> <password> [--gm]"
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "To start the servers:"
echo "  ./scripts/start-servers.sh"
echo ""
echo "Or manually:"
echo "  cd /home/trinitycore/server/bin"
echo "  ./authserver &"
echo "  ./worldserver"
echo ""
echo "For Thorium modding:"
echo "  cd /home/trinitycore/mods"
echo "  thorium help"
echo ""
