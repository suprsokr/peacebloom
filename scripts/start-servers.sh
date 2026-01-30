#!/bin/bash
# Start TrinityCore servers

# Check for background flag
BACKGROUND=false
if [ "$1" == "--background" ]; then
    BACKGROUND=true
fi

cd /home/trinitycore/server/bin

echo "=== Starting TrinityCore Servers ==="

# Ensure MySQL is running
if ! pgrep mysqld > /dev/null; then
    echo "Starting MySQL..."
    sudo service mysql start
    sleep 3
fi

# Start authserver
if pgrep -f authserver > /dev/null; then
    echo "Authserver already running"
else
    echo "Starting authserver..."
    nohup ./authserver > /tmp/authserver.log 2>&1 &
    sleep 2
fi

# Start worldserver
if pgrep -f worldserver > /dev/null; then
    echo "Worldserver already running"
    echo "To access console: docker exec -it trinitycore bash"
    echo "Then: cd /home/trinitycore/server/bin && ./worldserver"
else
    if [ "$BACKGROUND" = true ]; then
        echo "Starting worldserver in background..."
        nohup ./worldserver > /tmp/worldserver.log 2>&1 &
        sleep 3
        echo "Worldserver started. Logs: tail -f /tmp/worldserver.log"
        echo "To access console: docker exec -it trinitycore bash"
    else
        echo "Starting worldserver..."
        echo ""
        echo "=== Worldserver Console ==="
        echo "Create accounts with:"
        echo "  account create <username> <password>"
        echo "  account set gmlevel <username> 3 -1"
        echo ""
        echo "To run in background instead, use: start-servers.sh --background"
        echo ""
        ./worldserver
    fi
fi
