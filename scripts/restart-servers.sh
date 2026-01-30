#!/bin/bash
# Restart TrinityCore servers
# Useful after running `thorium build` to reload changes
#
# Usage: ./restart-servers.sh [--world-only] [--auth-only]

set -e

cd /home/trinitycore/server/bin

RESTART_WORLD=true
RESTART_AUTH=true

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --world-only)
            RESTART_AUTH=false
            shift
            ;;
        --auth-only)
            RESTART_WORLD=false
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--world-only] [--auth-only]"
            exit 1
            ;;
    esac
done

echo "=== Restarting TrinityCore Servers ==="

# Restart authserver
if [ "$RESTART_AUTH" = true ]; then
    if pgrep -f authserver > /dev/null; then
        echo "Stopping authserver..."
        pkill -f authserver || true
        sleep 1
    fi
    echo "Starting authserver..."
    nohup ./authserver > /tmp/authserver.log 2>&1 &
    sleep 2
    echo "Authserver restarted (PID: $(pgrep -f authserver))"
fi

# Restart worldserver
if [ "$RESTART_WORLD" = true ]; then
    if pgrep -f worldserver > /dev/null; then
        echo "Stopping worldserver..."
        # Send saveall command before killing (graceful shutdown)
        # This requires the worldserver to be running with a console
        pkill -f worldserver || true
        sleep 2
    fi
    echo "Starting worldserver in background..."
    nohup ./worldserver > /tmp/worldserver.log 2>&1 &
    sleep 3
    
    if pgrep -f worldserver > /dev/null; then
        echo "Worldserver restarted (PID: $(pgrep -f worldserver))"
        echo ""
        echo "View logs: tail -f /tmp/worldserver.log"
        echo "To access console, stop background server and run:"
        echo "  pkill -f worldserver && ./worldserver"
    else
        echo "ERROR: Worldserver failed to start. Check logs:"
        echo "  tail -50 /tmp/worldserver.log"
        exit 1
    fi
fi

echo ""
echo "=== Restart Complete ==="
