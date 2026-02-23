#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Provision a new client deployment on Heroku for Loc Vallis.

This script focuses ONLY on per-client configuration:
- Domain / URLs
- Stripe (secret key + webhook secret)
- Email (MAIL_FROM + SMTP_*)

It can:
- Create the Heroku app (optional)
- Set required config vars
- Add custom domain + enable Heroku Automated Certificate Management (optional)
- Scale web/worker dynos (optional)
 - Print Stripe webhook URL + required events (for manual Dashboard setup)

Required environment variables:
  HEROKU_APP            Heroku app name (e.g. loc-vallis-acme)
  CLIENT_DOMAIN         Custom domain (e.g. booking.acme.com)
  STRIPE_SECRET_KEY     Stripe secret key for THIS client (sk_live_... or sk_test_...)
  MAIL_FROM             Default From email (e.g. no-reply@acme.com)

Optional environment variables:
  APP_PROTOCOL          Defaults to https
  APP_BASE_URL          Defaults to ${APP_PROTOCOL}://${CLIENT_DOMAIN}

  SMTP_ADDRESS
  SMTP_PORT             Defaults to 587
  SMTP_USERNAME
  SMTP_PASSWORD
  SMTP_STARTTLS         Defaults to true
  SMTP_SSL              Defaults to false
  SMTP_AUTH             Defaults to plain
  SMTP_DOMAIN

  STRIPE_WEBHOOK_SECRET Set it if you already have the whsec_...

  PRIMARY_OWNER_EMAIL   (Recommended) The only allowed Owner email in production.
  HOST_DEFAULT_IMAGE_URL (Optional) Default image URL for /host page.

Optional flags:
  --create-app           Create the Heroku app if it doesn't exist
  --add-domain           Add the custom domain to the Heroku app and enable ACM
  --scale                Scale web=1 worker=1
  --db-prepare           Run rails db:prepare on Heroku

Examples:
  HEROKU_APP=lv-acme \
  CLIENT_DOMAIN=booking.acme.com \
  STRIPE_SECRET_KEY=sk_live_xxx \
  MAIL_FROM=no-reply@acme.com \
  SMTP_ADDRESS=smtp.mailgun.org SMTP_USERNAME=xxx SMTP_PASSWORD=yyy \
  ./script/provision_client.sh --create-app --add-domain --scale --db-prepare

USAGE
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

flag_create_app=false
flag_add_domain=false
flag_scale=false
flag_db_prepare=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --create-app)
      flag_create_app=true
      shift
      ;;
    --add-domain)
      flag_add_domain=true
      shift
      ;;
    --scale)
      flag_scale=true
      shift
      ;;
    --db-prepare)
      flag_db_prepare=true
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

: "${HEROKU_APP:?HEROKU_APP is required}"
: "${CLIENT_DOMAIN:?CLIENT_DOMAIN is required}"
: "${STRIPE_SECRET_KEY:?STRIPE_SECRET_KEY is required}"
: "${MAIL_FROM:?MAIL_FROM is required}"

APP_PROTOCOL="${APP_PROTOCOL:-https}"
APP_BASE_URL="${APP_BASE_URL:-${APP_PROTOCOL}://${CLIENT_DOMAIN}}"
SMTP_PORT="${SMTP_PORT:-587}"
SMTP_STARTTLS="${SMTP_STARTTLS:-true}"
SMTP_SSL="${SMTP_SSL:-false}"
SMTP_AUTH="${SMTP_AUTH:-plain}"

require_cmd heroku

if $flag_create_app; then
  if heroku apps:info -a "$HEROKU_APP" >/dev/null 2>&1; then
    echo "[OK] Heroku app exists: $HEROKU_APP"
  else
    echo "[..] Creating Heroku app: $HEROKU_APP"
    heroku apps:create "$HEROKU_APP" >/dev/null
  fi
else
  echo "[i] Skipping app creation. Ensure it exists: $HEROKU_APP"
fi

echo "[..] Setting config vars (domain/stripe/email)"

config_args=(
  "APP_HOST=$CLIENT_DOMAIN"
  "APP_PROTOCOL=$APP_PROTOCOL"
  "APP_BASE_URL=$APP_BASE_URL"
  "STRIPE_SECRET_KEY=$STRIPE_SECRET_KEY"
  "MAIL_FROM=$MAIL_FROM"
)

# Optional per-client identity / content
if [[ -n "${PRIMARY_OWNER_EMAIL:-}" ]]; then
  config_args+=("PRIMARY_OWNER_EMAIL=${PRIMARY_OWNER_EMAIL}")
fi

if [[ -n "${HOST_DEFAULT_IMAGE_URL:-}" ]]; then
  config_args+=("HOST_DEFAULT_IMAGE_URL=${HOST_DEFAULT_IMAGE_URL}")
fi

# Optional SMTP
if [[ -n "${SMTP_ADDRESS:-}" ]]; then
  config_args+=(
    "SMTP_ADDRESS=${SMTP_ADDRESS}"
    "SMTP_PORT=${SMTP_PORT}"
    "SMTP_USERNAME=${SMTP_USERNAME:-}"
    "SMTP_PASSWORD=${SMTP_PASSWORD:-}"
    "SMTP_STARTTLS=${SMTP_STARTTLS}"
    "SMTP_SSL=${SMTP_SSL}"
    "SMTP_AUTH=${SMTP_AUTH}"
    "SMTP_DOMAIN=${SMTP_DOMAIN:-}"
  )
fi

# Optional webhook secret (if already known)
if [[ -n "${STRIPE_WEBHOOK_SECRET:-}" ]]; then
  config_args+=("STRIPE_WEBHOOK_SECRET=${STRIPE_WEBHOOK_SECRET}")
fi

heroku config:set -a "$HEROKU_APP" "${config_args[@]}" >/dev/null

echo "[OK] Config vars set on $HEROKU_APP"
echo "     APP_BASE_URL=$APP_BASE_URL"

if $flag_add_domain; then
  echo "[..] Adding domain + enabling ACM (Heroku certs:auto)"
  heroku domains:add "$CLIENT_DOMAIN" -a "$HEROKU_APP" || true
  heroku certs:auto:enable -a "$HEROKU_APP" >/dev/null || true
  echo "[i] Next: point your DNS (CNAME/ALIAS) to the Heroku DNS target shown by:"
  echo "    heroku domains -a $HEROKU_APP"
fi

if $flag_scale; then
  echo "[..] Scaling dynos (web=1 worker=1)"
  heroku ps:scale web=1 worker=1 -a "$HEROKU_APP" >/dev/null
  echo "[OK] Dynos scaled"
fi

if $flag_db_prepare; then
  echo "[..] Running rails db:prepare"
  heroku run rails db:prepare -a "$HEROKU_APP"
fi

webhook_url="${APP_BASE_URL}/stripe/webhook"
echo "[i] Stripe Dashboard: create a webhook endpoint"
echo "    URL: $webhook_url"
echo "    Events: checkout.session.completed, checkout.session.async_payment_failed, checkout.session.expired, refund.updated"
echo "    Then set STRIPE_WEBHOOK_SECRET (whsec_...) on Heroku, e.g.:"
echo "    heroku config:set -a $HEROKU_APP STRIPE_WEBHOOK_SECRET=whsec_..."

echo "[DONE] $HEROKU_APP provisioned (domain/stripe/email)."
