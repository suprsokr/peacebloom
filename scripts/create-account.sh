#!/bin/bash
# Create a TrinityCore account directly in the database
# Uses SRP6 password hashing compatible with TrinityCore 3.3.5
#
# Usage: ./create-account.sh <username> <password> [--gm]
#        ./create-account.sh <username> <password> --gmlevel <0-3>
#
# GM Levels:
#   0 = Player (default)
#   1 = Moderator
#   2 = GameMaster  
#   3 = Administrator

set -e

# SRP6 parameters (from TrinityCore)
# g = 7
# N = 894B645E89E1535BBDAD5B8B290650530801B18EBFBF5E8FAB3C82872A3E9BB7 (big-endian)
G=7
N_HEX="894B645E89E1535BBDAD5B8B290650530801B18EBFBF5E8FAB3C82872A3E9BB7"

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
            echo "Creates a TrinityCore account directly in the database."
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

# Generate random 32-byte salt
SALT_HEX=$(openssl rand -hex 32)

# Calculate verifier using SRP6 algorithm:
# verifier = g ^ SHA1(salt || SHA1(username || ":" || password)) mod N
#
# Step 1: Calculate inner hash: SHA1(USERNAME:PASSWORD)
INNER_HASH=$(echo -n "${USERNAME_UPPER}:${PASSWORD_UPPER}" | openssl dgst -sha1 -binary | xxd -p -c 40)

# Step 2: Calculate x = SHA1(salt || inner_hash)
# Note: salt needs to be in binary form
X_HASH=$(echo -n "${SALT_HEX}${INNER_HASH}" | xxd -r -p | openssl dgst -sha1 -binary | xxd -p -c 40)

# Step 3: Calculate verifier = g^x mod N using openssl
# We need to use Python for the modular exponentiation since bash/openssl can't do bignum math easily
VERIFIER_HEX=$(python3 << EOF
g = $G
N = int("$N_HEX", 16)
x = int("$X_HASH", 16)
verifier = pow(g, x, N)
# Convert to 32-byte hex, little-endian (TrinityCore stores it this way)
v_bytes = verifier.to_bytes(32, byteorder='little')
print(v_bytes.hex())
EOF
)

# Convert salt to little-endian for storage (TrinityCore expects this)
SALT_LE=$(python3 << EOF
salt_bytes = bytes.fromhex("$SALT_HEX")
# Reverse for little-endian storage
print(salt_bytes[::-1].hex())
EOF
)

# Check if account already exists
EXISTING=$(sudo mysql -N -e "SELECT COUNT(*) FROM auth.account WHERE username = '$USERNAME_UPPER';" 2>/dev/null || echo "0")

if [ "$EXISTING" != "0" ]; then
    echo "Error: Account '$USERNAME' already exists!"
    exit 1
fi

# Insert account into database
sudo mysql auth << EOF
INSERT INTO account (username, salt, verifier, email, reg_mail, expansion)
VALUES (
    '$USERNAME_UPPER',
    X'$SALT_LE',
    X'$VERIFIER_HEX',
    '',
    '',
    2
);
EOF

# Get the new account ID
ACCOUNT_ID=$(sudo mysql -N -e "SELECT id FROM auth.account WHERE username = '$USERNAME_UPPER';")

# Set GM level if > 0
if [ "$GMLEVEL" -gt 0 ]; then
    sudo mysql auth << EOF
INSERT INTO account_access (AccountID, SecurityLevel, RealmID, Comment)
VALUES ($ACCOUNT_ID, $GMLEVEL, -1, 'Created by create-account.sh');
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
