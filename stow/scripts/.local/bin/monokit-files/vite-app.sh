#!/bin/bash

create_vite_app() {
  local DEST=$1
  local PKG_NAME=$2
  local TS_NAME=$3

  echo "🛠 Setting up Web (Vite + React) app..."
  
  # Web app package.json
  cat > "$DEST/package.json" <<EOL
{
  "name": "$PKG_NAME",
  "version": "0.0.1",
  "private": true,
  "scripts": {
    "build": "vite build",
    "dev": "vite",
    "preview": "vite preview",
    "lint": "eslint . --ext .ts,.tsx --config ../../eslint.config.js",
    "format": "prettier --write .",
    "test": "vitest run",
    "test:ui": "vitest --ui",
    "clean": "rm -rf dist",
    "type-check": "tsc --noEmit"
  }
}
EOL

  pnpm add --filter "$PKG_NAME" react react-dom
  pnpm add --filter "$PKG_NAME" -D vite @vitejs/plugin-react @types/react @types/react-dom @testing-library/react @testing-library/jest-dom jsdom
  
  cat > "$DEST/src/index.tsx" <<EOL
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOL

  cat > "$DEST/src/App.tsx" <<EOL
import React from 'react';
import { add, greet } from './utils';

function App() {
  const result = add(2, 3);
  const greeting = greet('React User');

  return (
    <div style={{ padding: '20px', fontFamily: 'Arial, sans-serif' }}>
      <h1>Hello from $TS_NAME React app!</h1>
      <p>2 + 3 = {result}</p>
      <p>{greeting}</p>
    </div>
  );
}

export default App;
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

  mkdir -p "$DEST/public"
  cat > "$DEST/index.html" <<EOL
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>$APP_NAME</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/index.tsx"></script>
  </body>
</html>
EOL

  # Vite config
  cat > "$DEST/vite.config.ts" <<EOL
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()]
});
EOL

  # Vitest config for React
  cat > "$DEST/vitest.config.ts" <<EOL
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/__tests__/setup.ts'],
  },
});
EOL

  # Create test folder and test file
  mkdir -p "$DEST/src/__tests__"
  
  # Test setup file
  cat > "$DEST/src/__tests__/setup.ts" <<EOL
import '@testing-library/jest-dom';
EOL

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

  # Create React component test
  cat > "$DEST/src/__tests__/App.test.tsx" <<EOL
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import App from '../App';

describe('App', () => {
  it('renders the app title', () => {
    render(<App />);
    expect(screen.getByText(/Hello from $TS_NAME React app!/)).toBeInTheDocument();
  });

  it('displays the calculation result', () => {
    render(<App />);
    expect(screen.getByText('2 + 3 = 5')).toBeInTheDocument();
  });

  it('displays the greeting', () => {
    render(<App />);
    expect(screen.getByText('Hello, React User!')).toBeInTheDocument();
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

  echo "✅ Vite React app created successfully"
} 