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
# Use setsid to properly detach from terminal and prevent signal issues
if pgrep -x authserver > /dev/null 2>&1; then
    echo "Authserver already running"
else
    echo "Starting authserver..."
    setsid ./authserver > /tmp/authserver.log 2>&1 &
    sleep 2
    if pgrep -x authserver > /dev/null 2>&1; then
        echo "Authserver started (PID: $(pgrep -x authserver))"
    else
        echo "Warning: Authserver may have failed to start. Check /tmp/authserver.log"
    fi
fi

# Start worldserver
if pgrep -x worldserver > /dev/null 2>&1; then
    echo "Worldserver already running"
    echo "To access console: docker exec -it trinitycore bash"
    echo "Then: cd /home/trinitycore/server/bin && ./worldserver"
else
    if [ "$BACKGROUND" = true ]; then
        echo "Starting worldserver in background..."
        setsid ./worldserver > /tmp/worldserver.log 2>&1 &
        sleep 5
        if pgrep -x worldserver > /dev/null 2>&1; then
            echo "Worldserver started (PID: $(pgrep -x worldserver))"
            echo "Logs: tail -f /tmp/worldserver.log"
        else
            echo "Warning: Worldserver may have failed to start. Check /tmp/worldserver.log"
        fi
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
