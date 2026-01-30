#!/bin/bash
# Create a TrinityCore account
#
# This script can work in two modes:
# 1. Bootstrap mode (no existing accounts): Creates account directly in database using SRP6
# 2. SOAP mode (existing GM account): Uses SOAP API for account creation
#
# Usage: ./create-gm-account.sh <username> <password> [--gm]
#        ./create-gm-account.sh <username> <password> --gmlevel <0-3>
#
# GM Levels:
#   0 = Player (default)
#   1 = Moderator
#   2 = GameMaster  
#   3 = Administrator

set -e

# Parse arguments
USERNAME=""
PASSWORD=""
GMLEVEL=0

while [[ $# -gt 0 ]]; do
    case $1 in
        --gm)
            GMLEVEL=3
            shift
            ;;
        --gmlevel)
            GMLEVEL="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 <username> <password> [--gm] [--gmlevel <0-3>]"
            echo ""
            echo "Creates a TrinityCore account."
            echo ""
            echo "Options:"
            echo "  --gm           Set GM level to 3 (Administrator)"
            echo "  --gmlevel <n>  Set specific GM level (0=Player, 1=Mod, 2=GM, 3=Admin)"
            echo ""
            echo "Examples:"
            echo "  $0 admin password123 --gm"
            echo "  $0 player mypass"
            exit 0
            ;;
        *)
            if [ -z "$USERNAME" ]; then
                USERNAME="$1"
            elif [ -z "$PASSWORD" ]; then
                PASSWORD="$1"
            else
                echo "Unknown argument: $1"
                exit 1
            fi
            shift
            ;;
    esac
done

if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo "Usage: $0 <username> <password> [--gm] [--gmlevel <0-3>]"
    exit 1
fi

# Convert to uppercase (SRP6 requires this)
USERNAME_UPPER=$(echo "$USERNAME" | tr '[:lower:]' '[:upper:]')
PASSWORD_UPPER=$(echo "$PASSWORD" | tr '[:lower:]' '[:upper:]')

echo "Creating account: $USERNAME (GM level: $GMLEVEL)"

# Check if account already exists
EXISTING=$(mysql -utrinity -ptrinity -N -e "SELECT COUNT(*) FROM auth.account WHERE username = '$USERNAME_UPPER';" 2>&1 | grep -v "Warning" || echo "0")

if [ "$EXISTING" != "0" ]; then
    echo "Error: Account '$USERNAME' already exists!"
    exit 1
fi

# Calculate SRP6 salt and verifier using Python
# Algorithm: v = g ^ SHA1(salt || SHA1(username || ':' || password)) mod N
# g = 7
# N = 894B645E89E1535BBDAD5B8B290650530801B18EBFBF5E8FAB3C82872A3E9BB7 (big-endian hex)
# Salt and verifier are stored as little-endian 32-byte arrays

read SALT_HEX VERIFIER_HEX < <(python3 << EOF
import hashlib
import os

# SRP6 constants (from TrinityCore)
g = 7
# N in big-endian
N_hex = "894B645E89E1535BBDAD5B8B290650530801B18EBFBF5E8FAB3C82872A3E9BB7"
N = int(N_hex, 16)

username = "${USERNAME_UPPER}"
password = "${PASSWORD_UPPER}"

# Generate random 32-byte salt
salt = os.urandom(32)

# Step 1: H(username || ':' || password)
h1 = hashlib.sha1((username + ":" + password).encode('utf-8')).digest()

# Step 2: H(salt || h1)
# Note: TrinityCore concatenates raw bytes
h2 = hashlib.sha1(salt + h1).digest()

# Convert h2 to integer (little-endian, as TrinityCore's BigNumber reads it)
x = int.from_bytes(h2, byteorder='little')

# Step 3: v = g^x mod N
v = pow(g, x, N)

# Convert verifier to 32-byte little-endian array
v_bytes = v.to_bytes(32, byteorder='little')

# Output salt and verifier as hex (already in storage format)
print(salt.hex(), v_bytes.hex())
EOF
)

# Insert account into database
mysql -utrinity -ptrinity auth 2>/dev/null << EOF
INSERT INTO account (username, salt, verifier, email, reg_mail, expansion)
VALUES (
    '$USERNAME_UPPER',
    X'$SALT_HEX',
    X'$VERIFIER_HEX',
    '',
    '',
    2
);
EOF

# Get the new account ID
ACCOUNT_ID=$(mysql -utrinity -ptrinity -N -e "SELECT id FROM auth.account WHERE username = '$USERNAME_UPPER';" 2>/dev/null)

# Set GM level if > 0
if [ "$GMLEVEL" -gt 0 ]; then
    mysql -utrinity -ptrinity auth 2>/dev/null << EOF
INSERT INTO account_access (AccountID, SecurityLevel, RealmID, Comment)
VALUES ($ACCOUNT_ID, $GMLEVEL, -1, 'Created by create-gm-account.sh');
EOF
    echo "Account created with GM level $GMLEVEL"
else
    echo "Account created (Player)"
fi

echo ""
echo "=== Account Created ==="
echo "Username: $USERNAME"
echo "Password: $PASSWORD"
echo "GM Level: $GMLEVEL"
echo ""
echo "You can now login to the game!"
