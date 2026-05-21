#!/usr/bin/env bash
set -euo pipefail

cd services/backend/supabase
supabase start
supabase db reset
