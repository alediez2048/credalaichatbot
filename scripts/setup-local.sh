#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="${ROOT_DIR}/backend"

if ! command -v ruby >/dev/null 2>&1; then
  echo "Ruby is not installed. Install ruby@3.2 first (brew install ruby@3.2)."
  exit 1
fi

RUBY_VERSION="$(ruby -e 'print RUBY_VERSION')"
RUBY_MAJOR="${RUBY_VERSION%%.*}"
RUBY_REST="${RUBY_VERSION#*.}"
RUBY_MINOR="${RUBY_REST%%.*}"

if [[ "${RUBY_MAJOR}" -lt 3 ]] || [[ "${RUBY_MAJOR}" -eq 3 && "${RUBY_MINOR}" -lt 1 ]]; then
  echo "Ruby ${RUBY_VERSION} detected. This project requires Ruby 3.1+ (3.2 recommended)."
  echo "Try: export PATH=\"/opt/homebrew/opt/ruby@3.2/bin:\$PATH\""
  exit 1
fi

if ! command -v redis-cli >/dev/null 2>&1; then
  echo "redis-cli is not installed. Install Redis first (brew install redis)."
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is not installed. Install Node.js first (brew install node)."
  exit 1
fi

# Try to make psql available when Postgres is installed via Homebrew
# but its bin directory is not on PATH yet.
if ! command -v psql >/dev/null 2>&1; then
  if [[ -x "/opt/homebrew/opt/postgresql@16/bin/psql" ]]; then
    export PATH="/opt/homebrew/opt/postgresql@16/bin:${PATH}"
  elif [[ -x "/opt/homebrew/opt/libpq/bin/psql" ]]; then
    export PATH="/opt/homebrew/opt/libpq/bin:${PATH}"
  fi
fi

if ! command -v psql >/dev/null 2>&1; then
  echo "Warning: psql not found on PATH. Continuing with Rails-based DB setup."
  echo "If DB commands fail, install Postgres client tools:"
  echo "  brew install postgresql@16"
  echo "or"
  echo "  brew install libpq && echo 'export PATH=\"/opt/homebrew/opt/libpq/bin:\$PATH\"' >> ~/.zshrc"
fi

echo "==> Running setup in ${BACKEND_DIR}"
cd "${BACKEND_DIR}"

if [[ ! -f .env ]]; then
  if [[ -f .env.example ]]; then
    cp .env.example .env
    echo "Created .env from .env.example (review DB credentials before first run)."
  else
    echo ".env.example not found; create .env manually."
  fi
fi

echo "==> Installing gems"
bundle install

echo "==> Installing npm dependencies"
npm install

echo "==> Creating and migrating database"
bundle exec rails db:create db:migrate

echo "==> Building JavaScript and CSS"
npm run build
npm run build:css

echo "==> Running test suite"
bundle exec rails test

echo
echo "Setup complete."
echo "Start the app with:"
echo "  cd \"${BACKEND_DIR}\" && bin/dev"
echo
echo "Then open:"
echo "  http://localhost:3000"
echo "  http://localhost:3000/onboarding"
