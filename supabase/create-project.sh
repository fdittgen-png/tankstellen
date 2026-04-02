#!/bin/bash
# ============================================================================
# TankSync — Create & Configure a New Supabase Project
# ============================================================================
#
# This script creates a brand-new Supabase project from scratch, applies
# the full TankSync schema, deploys Edge Functions, and outputs the
# credentials needed to configure the Tankstellen app.
#
# Usage:
#   chmod +x supabase/create-project.sh
#   ./supabase/create-project.sh
#
# Prerequisites:
#   - Supabase CLI installed (npx supabase or brew install supabase/tap/supabase)
#   - A Supabase account at https://supabase.com (free tier is fine)
#   - A Supabase access token (https://supabase.com/dashboard/account/tokens)
#
# What this script does:
#   1. Creates a new Supabase project via the Management API
#   2. Waits for the project to be ready
#   3. Links the local CLI to the new project
#   4. Pushes the database schema (10 tables, RLS, indexes)
#   5. Enables anonymous sign-ins (required for the app)
#   6. Deploys Edge Functions (alerts, price recording, report validation)
#   7. Outputs all credentials for app configuration
#
# ============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Colors & helpers
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║       TankSync — New Project Setup                      ║${NC}"
echo -e "${BOLD}║  Creates a personal Supabase backend for Tankstellen    ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# ---------------------------------------------------------------------------
# Step 0: Check prerequisites
# ---------------------------------------------------------------------------
info "Checking prerequisites..."

if ! command -v npx &> /dev/null; then
    error "Node.js/npx not found. Install from https://nodejs.org"
    exit 1
fi

# Verify supabase CLI is available
if ! npx supabase --version &> /dev/null 2>&1; then
    error "Supabase CLI not available. Install: npm install -g supabase"
    exit 1
fi

SUPABASE_VERSION=$(npx supabase --version 2>/dev/null)
success "Supabase CLI: $SUPABASE_VERSION"
success "Node.js: $(node --version)"

# ---------------------------------------------------------------------------
# Step 1: Collect user input
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}--- Configuration ---${NC}"
echo ""

# Access token
echo "You need a Supabase access token."
echo "Create one at: https://supabase.com/dashboard/account/tokens"
echo ""
read -rp "Supabase Access Token: " ACCESS_TOKEN
if [ -z "$ACCESS_TOKEN" ]; then
    error "Access token is required."
    exit 1
fi

# Organization
echo ""
info "Fetching your organizations..."
ORGS_JSON=$(SUPABASE_ACCESS_TOKEN="$ACCESS_TOKEN" npx supabase orgs list --output json 2>/dev/null || echo "[]")

if [ "$ORGS_JSON" = "[]" ] || [ -z "$ORGS_JSON" ]; then
    error "No organizations found. Create one at https://supabase.com/dashboard/org/new"
    exit 1
fi

echo ""
echo "Your organizations:"
echo "$ORGS_JSON" | node -e "
const orgs = JSON.parse(require('fs').readFileSync(0, 'utf8'));
orgs.forEach((o, i) => console.log('  ' + (i+1) + '. ' + o.name + ' (ID: ' + o.id + ')'));
"

echo ""
read -rp "Enter organization ID (or number from list): " ORG_INPUT

# Allow selecting by number
ORG_ID=$(echo "$ORGS_JSON" | node -e "
const orgs = JSON.parse(require('fs').readFileSync(0, 'utf8'));
const input = '$ORG_INPUT';
const num = parseInt(input);
if (!isNaN(num) && num >= 1 && num <= orgs.length) {
    console.log(orgs[num-1].id);
} else {
    console.log(input);
}
")

if [ -z "$ORG_ID" ]; then
    error "Organization ID is required."
    exit 1
fi
success "Organization: $ORG_ID"

# Project name
echo ""
read -rp "Project name [tankstellen]: " PROJECT_NAME
PROJECT_NAME="${PROJECT_NAME:-tankstellen}"

# Database password
echo ""
echo "Choose a strong database password (min 12 characters)."
read -rsp "Database password: " DB_PASSWORD
echo ""
if [ ${#DB_PASSWORD} -lt 12 ]; then
    error "Password must be at least 12 characters."
    exit 1
fi

# Region
echo ""
echo "Available regions:"
echo "  1. eu-central-1    (Frankfurt, Germany)"
echo "  2. eu-west-1       (Ireland)"
echo "  3. eu-west-2       (London, UK)"
echo "  4. eu-west-3       (Paris, France)"
echo "  5. us-east-1       (N. Virginia, USA)"
echo "  6. us-west-1       (N. California, USA)"
echo "  7. ap-southeast-1  (Singapore)"
echo ""
read -rp "Select region [1]: " REGION_NUM
REGION_NUM="${REGION_NUM:-1}"

case "$REGION_NUM" in
    1) REGION="eu-central-1" ;;
    2) REGION="eu-west-1" ;;
    3) REGION="eu-west-2" ;;
    4) REGION="eu-west-3" ;;
    5) REGION="us-east-1" ;;
    6) REGION="us-west-1" ;;
    7) REGION="ap-southeast-1" ;;
    *) REGION="$REGION_NUM" ;;  # Allow raw region string
esac

success "Region: $REGION"

# Optional: Tankerkoenig API key
echo ""
echo "Optional: Tankerkoenig API key for German price alerts."
echo "Get one free at: https://creativecommons.tankerkoenig.de/"
read -rp "Tankerkoenig API key (Enter to skip): " TK_API_KEY

# ---------------------------------------------------------------------------
# Step 2: Create the Supabase project
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}--- Creating Project ---${NC}"
echo ""
info "Creating Supabase project '$PROJECT_NAME' in $REGION..."

CREATE_RESULT=$(SUPABASE_ACCESS_TOKEN="$ACCESS_TOKEN" npx supabase projects create "$PROJECT_NAME" \
    --org-id "$ORG_ID" \
    --db-password "$DB_PASSWORD" \
    --region "$REGION" \
    --output json 2>/dev/null)

PROJECT_REF=$(echo "$CREATE_RESULT" | node -e "
const data = JSON.parse(require('fs').readFileSync(0, 'utf8'));
console.log(data.id || '');
")

if [ -z "$PROJECT_REF" ]; then
    error "Failed to create project. Response:"
    echo "$CREATE_RESULT"
    exit 1
fi

success "Project created: $PROJECT_REF"

# ---------------------------------------------------------------------------
# Step 3: Wait for project to be ready
# ---------------------------------------------------------------------------
info "Waiting for project to initialize (this takes 1-3 minutes)..."

MAX_WAIT=180  # 3 minutes
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    STATUS=$(SUPABASE_ACCESS_TOKEN="$ACCESS_TOKEN" npx supabase projects list --output json 2>/dev/null | \
        node -e "
const projects = JSON.parse(require('fs').readFileSync(0, 'utf8'));
const p = projects.find(p => p.id === '$PROJECT_REF');
console.log(p ? p.status : 'UNKNOWN');
" 2>/dev/null || echo "UNKNOWN")

    if [ "$STATUS" = "ACTIVE_HEALTHY" ] || [ "$STATUS" = "ACTIVE" ]; then
        break
    fi

    echo -ne "\r  Waiting... ${WAITED}s (status: $STATUS)  "
    sleep 5
    WAITED=$((WAITED + 5))
done
echo ""

if [ $WAITED -ge $MAX_WAIT ]; then
    warn "Project may still be initializing. Continuing anyway..."
else
    success "Project is ready!"
fi

# ---------------------------------------------------------------------------
# Step 4: Link and push schema
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}--- Deploying Schema ---${NC}"
echo ""

info "Linking to project..."
cd "$PROJECT_ROOT"
SUPABASE_ACCESS_TOKEN="$ACCESS_TOKEN" npx supabase link --project-ref "$PROJECT_REF" -p "$DB_PASSWORD" 2>/dev/null
success "Project linked"

info "Pushing database schema..."
echo "Y" | SUPABASE_ACCESS_TOKEN="$ACCESS_TOKEN" npx supabase db push -p "$DB_PASSWORD" 2>/dev/null
success "Schema deployed (10 tables, RLS policies, indexes)"

# ---------------------------------------------------------------------------
# Step 5: Enable anonymous sign-ins via Management API
# ---------------------------------------------------------------------------
echo ""
info "Enabling anonymous sign-ins..."

# Use the Supabase Management API to update auth config
AUTH_UPDATE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PATCH \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"enable_anonymous_sign_ins": true}' \
    "https://api.supabase.com/v1/projects/$PROJECT_REF/config/auth" 2>/dev/null || echo "000")

if [ "$AUTH_UPDATE" = "200" ]; then
    success "Anonymous sign-ins enabled"
else
    warn "Could not auto-enable anonymous sign-ins (HTTP $AUTH_UPDATE)."
    warn "Please enable manually: Dashboard -> Authentication -> Settings -> Enable Anonymous Sign-ins"
fi

# ---------------------------------------------------------------------------
# Step 6: Deploy Edge Functions
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}--- Deploying Edge Functions ---${NC}"
echo ""

FUNCTIONS_DEPLOYED=0

for FUNC in check-alerts record-prices validate-report; do
    if [ -d "$SCRIPT_DIR/functions/$FUNC" ]; then
        info "Deploying $FUNC..."
        if SUPABASE_ACCESS_TOKEN="$ACCESS_TOKEN" npx supabase functions deploy "$FUNC" --project-ref "$PROJECT_REF" 2>/dev/null; then
            success "$FUNC deployed"
            FUNCTIONS_DEPLOYED=$((FUNCTIONS_DEPLOYED + 1))
        else
            warn "Failed to deploy $FUNC (non-fatal)"
        fi
    fi
done

if [ $FUNCTIONS_DEPLOYED -gt 0 ]; then
    success "$FUNCTIONS_DEPLOYED Edge Functions deployed"
fi

# Set Tankerkoenig API key if provided
if [ -n "${TK_API_KEY:-}" ]; then
    info "Setting Tankerkoenig API key..."
    SUPABASE_ACCESS_TOKEN="$ACCESS_TOKEN" npx supabase secrets set \
        TANKERKOENIG_API_KEY="$TK_API_KEY" \
        --project-ref "$PROJECT_REF" 2>/dev/null
    success "API key stored"
fi

# ---------------------------------------------------------------------------
# Step 7: Retrieve credentials
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}--- Retrieving Credentials ---${NC}"
echo ""

info "Fetching API keys..."

API_KEYS_JSON=$(SUPABASE_ACCESS_TOKEN="$ACCESS_TOKEN" npx supabase projects api-keys --project-ref "$PROJECT_REF" --output json 2>/dev/null || echo "[]")

ANON_KEY=$(echo "$API_KEYS_JSON" | node -e "
const keys = JSON.parse(require('fs').readFileSync(0, 'utf8'));
const anon = keys.find(k => k.name === 'anon');
console.log(anon ? anon.api_key : '');
" 2>/dev/null || echo "")

SERVICE_ROLE_KEY=$(echo "$API_KEYS_JSON" | node -e "
const keys = JSON.parse(require('fs').readFileSync(0, 'utf8'));
const sr = keys.find(k => k.name === 'service_role');
console.log(sr ? sr.api_key : '');
" 2>/dev/null || echo "")

SUPABASE_URL="https://${PROJECT_REF}.supabase.co"

# ---------------------------------------------------------------------------
# Step 8: Generate config file for the app
# ---------------------------------------------------------------------------
CONFIG_FILE="$PROJECT_ROOT/assets/tanksync_config.json"
mkdir -p "$PROJECT_ROOT/assets"

cat > "$CONFIG_FILE" << JSONEOF
{
  "supabase_url": "$SUPABASE_URL",
  "supabase_anon_key": "$ANON_KEY",
  "project_ref": "$PROJECT_REF",
  "region": "$REGION",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
JSONEOF

success "Config written to assets/tanksync_config.json"

# ---------------------------------------------------------------------------
# Output summary
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║                    Setup Complete!                          ║${NC}"
echo -e "${BOLD}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BOLD}║                                                            ║${NC}"
echo -e "${BOLD}║  ${GREEN}Your TankSync backend is ready.${NC}${BOLD}                          ║${NC}"
echo -e "${BOLD}║                                                            ║${NC}"
echo -e "${BOLD}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BOLD}║  APP CONFIGURATION                                         ║${NC}"
echo -e "${BOLD}╠══════════════════════════════════════════════════════════════╣${NC}"
echo ""
echo -e "  ${CYAN}Supabase URL:${NC}"
echo -e "  ${GREEN}$SUPABASE_URL${NC}"
echo ""
echo -e "  ${CYAN}Anon Key:${NC}"
echo -e "  ${GREEN}${ANON_KEY:-<check dashboard>}${NC}"
echo ""
echo -e "  ${CYAN}Project Reference:${NC}"
echo -e "  ${GREEN}$PROJECT_REF${NC}"
echo ""
echo -e "${BOLD}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BOLD}║  ADMIN CREDENTIALS (keep secret!)                          ║${NC}"
echo -e "${BOLD}╠══════════════════════════════════════════════════════════════╣${NC}"
echo ""
echo -e "  ${CYAN}Service Role Key:${NC}"
echo -e "  ${YELLOW}${SERVICE_ROLE_KEY:-<check dashboard>}${NC}"
echo ""
echo -e "  ${CYAN}Database Password:${NC}"
echo -e "  ${YELLOW}(the password you entered above)${NC}"
echo ""
echo -e "${BOLD}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BOLD}║  HOW TO USE                                                ║${NC}"
echo -e "${BOLD}╠══════════════════════════════════════════════════════════════╣${NC}"
echo ""
echo "  Option A: Use as community database (built into app)"
echo "    Update assets/tanksync_config.json (already done!)"
echo "    Rebuild the app: flutter build apk --release"
echo ""
echo "  Option B: Enter manually in the app"
echo "    Settings -> TankSync -> Connect -> Private/Join"
echo "    Paste the Supabase URL and Anon Key above"
echo ""
echo "  Option C: Build with custom config"
echo "    flutter build apk --dart-define=COMMUNITY_SUPABASE_URL=$SUPABASE_URL"
echo "                      --dart-define=COMMUNITY_SUPABASE_ANON_KEY=$ANON_KEY"
echo ""
echo -e "${BOLD}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BOLD}║  LINKS                                                     ║${NC}"
echo -e "${BOLD}╠══════════════════════════════════════════════════════════════╣${NC}"
echo ""
echo "  Dashboard:  https://supabase.com/dashboard/project/$PROJECT_REF"
echo "  API Keys:   https://supabase.com/dashboard/project/$PROJECT_REF/settings/api"
echo "  Auth:       https://supabase.com/dashboard/project/$PROJECT_REF/auth/users"
echo "  Functions:  https://supabase.com/dashboard/project/$PROJECT_REF/functions"
echo "  SQL Editor: https://supabase.com/dashboard/project/$PROJECT_REF/sql"
echo ""
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Done! Your TankSync backend is ready to use.${NC}"
echo ""
