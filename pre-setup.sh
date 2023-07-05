#!/bin/bash

# Set the root directory
if [ -z "$1" ] || [ "$1" = "." ]; then
  ROOT_DIR="$(pwd)"
else
  ROOT_DIR="$1"
fi

# Install Husky if it's not already installed
if ! command -v husky &> /dev/null
then
  npm install husky --save-dev
fi

# Configure Husky to run pre-commit tests
cd "$ROOT_DIR"
npm install eslint
npx husky-init
mkdir -p .husky
cat << 'EOF' > .husky/pre-commit
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

# Run ESLint with the rule to detect unused imports
eslint_output=$(npx eslint --max-warnings=0 --ext .js,.jsx,.ts,.tsx .)

npx lint-staged
EOF
chmod +x .husky/pre-commit

# Configure lint-staged to run pre-commit tests
npm install lint-staged --save-dev
npx json -I -f package.json -e 'this["lint-staged"]={"*.{js,jsx,ts,tsx}":["npx prettier --write","npm test -- --watchAll=false --findRelatedTests --bail","npx eslint"]}'


