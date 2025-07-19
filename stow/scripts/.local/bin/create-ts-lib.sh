#!/bin/bash

set -e

PROJECT_NAME=$1

if [ -z "$PROJECT_NAME" ]; then
  echo "❌ Usage: ./create-ts-lib.sh my-lib-name"
  exit 1
fi

echo "🚀 Creating TypeScript library: $PROJECT_NAME"
mkdir "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Init npm
npm init -y

# Install dev dependencies
npm install --save-dev \
  typescript \
  tsup \
  eslint \
  prettier \
  eslint-config-prettier \
  eslint-plugin-import \
  @typescript-eslint/parser \
  @typescript-eslint/eslint-plugin \
  vitest \
  @vitest/ui \
  @types/node \
  json

# Directory structure
mkdir -p src test .github/workflows .github/ISSUE_TEMPLATE

# Sample source
cat > src/index.ts <<'EOL'
export const greet = (name: string): string => {
  return `Hello, ${name}!`;
};

// console.log(greet("World"));
EOL

# Sample test
cat > test/index.test.ts <<'EOL'
import { describe, it, expect } from 'vitest';
import { greet } from '../src';

describe('greet', () => {
  it('returns a greeting', () => {
    expect(greet('World')).toBe('Hello, World!');
  });
});
EOL

# tsconfig.json
cat > tsconfig.json <<'EOL'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "declaration": true,
    "outDir": "dist",
    "strict": true,
    "esModuleInterop": true,
    "moduleResolution": "node",
    "forceConsistentCasingInFileNames": true,
    "skipLibCheck": true
  },
  "include": ["src"]
}
EOL

# tsconfig for lint
cat > tsconfig.eslint.json <<'EOL'
{
  "extends": "./tsconfig.json",
  "include": ["src", "test", "vitest.config.ts"]
}
EOL

# ESLint config (flat)
cat > eslint.config.mjs <<'EOL'
import eslintPluginTs from '@typescript-eslint/eslint-plugin';
import parserTs from '@typescript-eslint/parser';
import pluginImport from 'eslint-plugin-import';

export default [
  {
    files: ['src/**/*.ts', 'test/**/*.ts'],
    languageOptions: {
      parser: parserTs,
      parserOptions: {
        project: './tsconfig.eslint.json',
        tsconfigRootDir: process.cwd(),
        sourceType: 'module'
      }
    },
    plugins: {
      '@typescript-eslint': eslintPluginTs,
      import: pluginImport
    },
    rules: {
      'no-unused-vars': 'off',
      '@typescript-eslint/no-unused-vars': ['warn'],
      'import/order': [
        'warn',
        {
          groups: ['builtin', 'external', 'internal'],
          alphabetize: { order: 'asc', caseInsensitive: true }
        }
      ]
    }
  }
];
EOL

# Prettier
cat > .prettierrc <<'EOL'
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "all",
  "printWidth": 80
}
EOL

# Gitignore
cat > .gitignore <<'EOL'
node_modules/
dist/
coverage/
.env
.DS_Store
EOL

# README.md
cat > README.md <<'EOL'
# $PROJECT_NAME

A modern TypeScript library skeleton using:

- TypeScript
- Tsup for fast builds
- Vitest for testing
- ESLint + Prettier for linting/formatting
- GitHub Actions for CI/CD
- Ready to publish on npm

## Structure

src/            - Your source code
test/           - Unit tests
dist/           - Compiled output (ignored in git)
.github/        - CI/CD config and templates

## Scripts

npm run build    - Builds the library to dist/
npm run dev      - Watches and runs dist/index.js
npm run watch    - Just rebuilds on file changes
npm run test     - Runs tests via Vitest
npm run lint     - Lints code with ESLint
npm run format   - Formats code with Prettier

## GitHub Actions

- ci.yml: runs tests on PRs and on push to main
- release.yml: publishes to npm when a tag (e.g. v1.0.0) is pushed

To publish:

git tag v1.0.0
git push origin v1.0.0

Make sure your NPM_TOKEN is set in GitHub secrets.

## Contributing

Submit issues and PRs — templates are included!
EOL

# Vitest config
cat > vitest.config.ts <<'EOL'
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    coverage: {
      reporter: ['text', 'json', 'html']
    }
  }
});
EOL

# Package scripts
npx json -I -f package.json -e '
this.scripts = {
  "build": "tsup src/index.ts --dts --format esm,cjs",
  "watch": "tsup src/index.ts --watch --format esm,cjs",
  "dev": "tsup src/index.ts --watch --onSuccess \"node dist/index.js\"",
  "lint": "eslint . --ext .ts",
  "format": "prettier --write .",
  "test": "vitest run",
  "test:ui": "vitest --ui"
};
this.main = "dist/index.js";
this.types = "dist/index.d.ts";
'

# GitHub CI: test on PRs and main
cat > .github/workflows/ci.yml <<'EOL'
name: CI

on:
  pull_request:
  push:
    branches:
      - main

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - run: npm run lint
      - run: npm run test
EOL

# GitHub CI: npm publish on tag
cat > .github/workflows/release.yml <<'EOL'
name: Release

on:
  push:
    tags:
      - 'v*.*.*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          registry-url: 'https://registry.npmjs.org/'
      - run: npm ci
      - run: npm run build
      - run: npm publish
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
EOL

# GitHub templates
cat > .github/PULL_REQUEST_TEMPLATE.md <<'EOL'
## What Changed?

## Checklist

- [ ] Tests added/updated
- [ ] Code linted
- [ ] Docs updated (if needed)
EOL

cat > .github/ISSUE_TEMPLATE/bug_report.md <<'EOL'
---
name: Bug report
about: Report a problem
title: ''
labels: bug
assignees: ''

---

## Describe the bug

## Version

## Steps to Reproduce

## Expected Behavior

## Screenshots or Logs
EOL

echo "✅ $PROJECT_NAME is ready with full CI/CD, lint, and build support!"
