#!/bin/bash

create_express_app() {
  local DEST=$1
  local PKG_NAME=$2
  local TS_NAME=$3

  echo "🛠 Setting up Express API app..."
  
  # API package.json
  cat > "$DEST/package.json" <<EOL
{
  "name": "$PKG_NAME",
  "version": "0.0.1",
  "private": true,
  "scripts": {
    "build": "tsup src/index.ts --format esm,cjs",
    "watch": "tsup src/index.ts --watch",
    "dev": "tsup src/index.ts --watch --onSuccess \\"node dist/index.js\\"",
    "start": "node dist/index.js",
    "lint": "eslint . --ext .ts --config ../../eslint.config.js",
    "format": "prettier --write .",
    "test": "vitest run",
    "test:ui": "vitest --ui",
    "clean": "rm -rf dist",
    "type-check": "tsc --noEmit"
  }
}
EOL

  pnpm add --filter "$PKG_NAME" express
  
  cat > "$DEST/src/index.ts" <<EOL
import express from 'express';
import { add, greet } from './utils';

const app = express();
app.use(express.json());

app.get('/', (_req, res) => {
  res.json({ 
    message: 'Hello from $TS_NAME API!',
    example: add(2, 3),
    greeting: greet('API User')
  });
});

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: '$TS_NAME' });
});

app.post('/calculate', (req, res) => {
  const { a, b } = req.body;
  if (typeof a !== 'number' || typeof b !== 'number') {
    return res.status(400).json({ error: 'Both a and b must be numbers' });
  }
  res.json({ result: add(a, b) });
});

app.listen(3000, () => {
  console.log('$TS_NAME API running at http://localhost:3000');
});
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

  echo "✅ Express API app created successfully"
} 