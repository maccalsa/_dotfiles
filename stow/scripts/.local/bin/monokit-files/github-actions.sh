#!/bin/bash

setup_github_actions() {
  mkdir -p .github/workflows .github/ISSUE_TEMPLATE

  # CI Workflow
  cat > .github/workflows/ci.yml <<EOL
name: CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: corepack enable
      - run: pnpm install
      - run: pnpm type-check
      - run: pnpm lint
      - run: pnpm format --check
      - run: pnpm test
      - run: pnpm build
EOL

  # Release Workflow
  cat > .github/workflows/release.yml <<EOL
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
      - run: corepack enable
      - run: pnpm install
      - run: pnpm type-check
      - run: pnpm lint
      - run: pnpm build
      - run: pnpm release
        env:
          NODE_AUTH_TOKEN: \${{ secrets.NPM_TOKEN }}
EOL

  # PR Template
  cat > .github/PULL_REQUEST_TEMPLATE.md <<EOL
## ✨ Summary

<!-- Describe your changes -->

## ✅ Checklist

- [ ] Tests added/updated
- [ ] Code linted and formatted
- [ ] Type checking passes
- [ ] Build passes
- [ ] Docs updated (if needed)
EOL

  # Issue Templates
  cat > .github/ISSUE_TEMPLATE/bug.md <<EOL
---
name: 🐛 Bug Report
about: Something is broken
title: '[BUG] '
labels: bug
assignees: ''

---

## 🐞 Describe the bug

## 🔁 Reproduce

## 📦 Version

## 🖼️ Screenshots or logs
EOL

  cat > .github/ISSUE_TEMPLATE/feature.md <<EOL
---
name: 💡 Feature Request
about: Suggest a new feature
title: '[FEATURE] '
labels: enhancement
assignees: ''

---

## 💡 Describe the feature

## 🔧 Use case or motivation

## 🤔 Alternatives considered
EOL

  echo "✅ GitHub Actions + templates created"
}

