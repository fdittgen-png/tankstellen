#!/bin/bash
# Deploy Supabase Edge Functions and apply migrations.
# Usage: bash supabase/deploy.sh
#
# Prerequisites:
# - supabase CLI installed and linked to the project
# - SUPABASE_ACCESS_TOKEN set in environment

set -e

echo "Deploying Edge Functions..."
supabase functions deploy check-alerts --no-verify-jwt
supabase functions deploy record-prices --no-verify-jwt
supabase functions deploy validate-report --no-verify-jwt

echo "Applying database migrations..."
supabase db push

echo "Done. Edge Functions deployed and pg_cron schedules applied."
echo ""
echo "Verify with:"
echo "  supabase functions list"
echo "  SELECT * FROM cron.job;  -- in SQL editor"
