#!/bin/bash
# ============================================================================
# TankSync Self-Service Setup Script
# ============================================================================
# This script helps users create their own TankSync backend on Supabase.
# Run it after creating a free Supabase project at https://supabase.com
#
# Usage:
#   chmod +x supabase/setup.sh
#   ./supabase/setup.sh
#
# Prerequisites:
#   - Node.js 18+ installed
#   - A Supabase account (free tier is fine)
#   - A Supabase project created at https://supabase.com/dashboard/new
# ============================================================================

set -e

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║         TankSync — Self-Service Setup               ║"
echo "║  Optional backend for the Tankstellen fuel app      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# Check prerequisites
if ! command -v npx &> /dev/null; then
    echo "ERROR: Node.js/npx not found. Install from https://nodejs.org"
    exit 1
fi

echo "This script will:"
echo "  1. Link to your Supabase project"
echo "  2. Push the database schema (tables, RLS, indexes)"
echo "  3. Deploy Edge Functions (alert checker, price recorder)"
echo "  4. Show you the credentials to enter in the app"
echo ""

# Get project details
read -p "Enter your Supabase Project Reference ID: " PROJECT_REF
if [ -z "$PROJECT_REF" ]; then
    echo "ERROR: Project reference is required."
    echo "Find it at: https://supabase.com/dashboard/project/YOUR_PROJECT/settings/general"
    exit 1
fi

read -p "Enter your Supabase Access Token (from https://supabase.com/dashboard/account/tokens): " ACCESS_TOKEN
if [ -z "$ACCESS_TOKEN" ]; then
    echo "ERROR: Access token is required."
    exit 1
fi

read -sp "Enter your database password: " DB_PASSWORD
echo ""

# Optional: Tankerkoenig API key for German price alerts
read -p "Enter Tankerkoenig API key (optional, for DE price alerts — press Enter to skip): " TK_API_KEY

echo ""
echo "Step 1/4: Linking project..."
SUPABASE_ACCESS_TOKEN="$ACCESS_TOKEN" npx supabase link --project-ref "$PROJECT_REF" -p "$DB_PASSWORD"
echo "  ✓ Project linked"

echo ""
echo "Step 2/4: Pushing database schema..."
SUPABASE_ACCESS_TOKEN="$ACCESS_TOKEN" npx supabase db push -p "$DB_PASSWORD" <<< "Y"
echo "  ✓ Schema deployed (7 tables, RLS policies, indexes)"

echo ""
echo "Step 3/4: Deploying Edge Functions..."
SUPABASE_ACCESS_TOKEN="$ACCESS_TOKEN" npx supabase functions deploy check-alerts --project-ref "$PROJECT_REF"
SUPABASE_ACCESS_TOKEN="$ACCESS_TOKEN" npx supabase functions deploy record-prices --project-ref "$PROJECT_REF"
SUPABASE_ACCESS_TOKEN="$ACCESS_TOKEN" npx supabase functions deploy validate-report --project-ref "$PROJECT_REF"
echo "  ✓ 3 Edge Functions deployed"

if [ -n "$TK_API_KEY" ]; then
    echo ""
    echo "Step 3b: Setting Tankerkoenig API key..."
    SUPABASE_ACCESS_TOKEN="$ACCESS_TOKEN" npx supabase secrets set TANKERKOENIG_API_KEY="$TK_API_KEY" --project-ref "$PROJECT_REF"
    echo "  ✓ API key stored"
fi

echo ""
echo "Step 4/4: Getting your credentials..."
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  Setup Complete!                                     ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║                                                      ║"
echo "║  Enter these in the Tankstellen app:                 ║"
echo "║  Settings → TankSync → Connect                       ║"
echo "║                                                      ║"
echo "║  Supabase URL:                                       ║"
echo "║  https://${PROJECT_REF}.supabase.co                  ║"
echo "║                                                      ║"
echo "║  Find your anon key at:                              ║"
echo "║  https://supabase.com/dashboard/project/${PROJECT_REF}/settings/api"
echo "║                                                      ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  IMPORTANT: Enable Anonymous Sign-ins!               ║"
echo "║  Go to: Dashboard → Authentication → Settings        ║"
echo "║  Toggle 'Enable Anonymous Sign-ins' → ON             ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "Dashboard: https://supabase.com/dashboard/project/${PROJECT_REF}"
echo "Functions: https://supabase.com/dashboard/project/${PROJECT_REF}/functions"
echo ""
echo "Done! Your TankSync backend is ready."
