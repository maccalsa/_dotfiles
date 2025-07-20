#!/bin/bash

create_cli_app() {
  local DEST=$1
  local PKG_NAME=$2
  local TS_NAME=$3

  echo "🛠 Setting up CLI app..."
  
  # CLI package.json
  cat > "$DEST/package.json" <<EOL
{
  "name": "$PKG_NAME",
  "version": "0.0.1",
  "private": true,
  "scripts": {
    "build": "tsup src/index.ts --format esm,cjs",
    "watch": "tsup src/index.ts --watch",
    "dev": "tsup src/index.ts --watch --onSuccess \\"node dist/index.js\\"",
    "lint": "eslint . --ext .ts --config ../../eslint.config.js",
    "format": "prettier --write .",
    "test": "vitest run",
    "test:ui": "vitest --ui",
    "clean": "rm -rf dist",
    "type-check": "tsc --noEmit"
  }
}
EOL

  pnpm add --filter "$PKG_NAME" chalk
  
  cat > "$DEST/src/index.ts" <<EOL
import chalk from 'chalk';
import { add, greet } from './utils';

/**
 * Main CLI function
 */
export const runCLI = () => {
  console.log(chalk.green('Hello from $TS_NAME CLI app!'));
  console.log(chalk.blue('2 + 3 =', add(2, 3)));
  console.log(chalk.yellow(greet('User')));
};

// Run the CLI if this file is executed directly
if (import.meta.url === \`file://\${process.argv[1]}\`) {
  runCLI();
}
EOL

  # Create utils file with functions
  cat > "$DEST/src/utils.ts" <<EOL
/**
 * Adds two numbers together
 * @param a - First number
 * @param b - Second number
 * @returns The sum of a and b
 */
export const add = (a: number, b: number): number => {
  return a + b;
};

/**
 * Greets a person by name
 * @param name - The name to greet
 * @returns A greeting message
 */
export const greet = (name: string): string => {
  return \`Hello, \${name}!\`;
};
EOL

  # Create test folder and test file
  mkdir -p "$DEST/src/__tests__"
  cat > "$DEST/src/__tests__/utils.test.ts" <<EOL
import { describe, it, expect } from 'vitest';
import { add, greet } from '../utils';

describe('$TS_NAME utils', () => {
  describe('add', () => {
    it('should add two positive numbers', () => {
      expect(add(2, 3)).toBe(5);
    });

    it('should add negative numbers', () => {
      expect(add(-1, -2)).toBe(-3);
    });

    it('should add zero', () => {
      expect(add(5, 0)).toBe(5);
    });
  });

  describe('greet', () => {
    it('should greet a person by name', () => {
      expect(greet('Alice')).toBe('Hello, Alice!');
    });

    it('should handle empty string', () => {
      expect(greet('')).toBe('Hello, !');
    });
  });
});
EOL

  # TypeScript config
  cat > "$DEST/tsconfig.json" <<EOL
{
  "extends": "../../tsconfig.base.json",
  "include": ["src"]
}
EOL

  # Vitest config
  cat > "$DEST/vitest.config.ts" <<EOL
import { defineConfig } from 'vitest/config';
export default defineConfig({ test: { globals: true, environment: 'node' } });
EOL

  echo "✅ CLI app created successfully"
} 