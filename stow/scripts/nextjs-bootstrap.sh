#!/usr/bin/env bash
set -euo pipefail

# --------- Error Handling ---------
cleanup_on_error() {
  if [[ -d "${project_name:-}" ]]; then
    echo "❌ Setup failed. Cleaning up..."
    cd ..
    rm -rf "$project_name"
  fi
}

trap cleanup_on_error ERR

# --------- Helpers ---------
abort() { echo "$@" >&2; exit 1; }

# --------- Validation Functions ---------
validate_project_name() {
  local name="$1"
  # Check for valid project name (alphanumeric, hyphens, underscores only)
  if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    abort "Project name must contain only letters, numbers, hyphens, and underscores"
  fi
  # Check length
  if [[ ${#name} -lt 1 || ${#name} -gt 50 ]]; then
    abort "Project name must be between 1 and 50 characters"
  fi
}

validate_database_url() {
  local url="$1"
  # Basic URL format validation
  # if [[ ! "$url" =~ ^(postgresql|postgres|mysql|sqlite):// ]]; then
  #   abort "Database URL must start with postgresql://, postgres://, mysql://, or sqlite://"
  # fi
}

validate_openai_key() {
  local key="$1"
  # OpenAI API keys start with 'sk-' and are typically 51 characters
  # if [[ ! "$key" =~ ^sk-[a-zA-Z0-9]+$ ]]; then
  #   abort "OpenAI API key must start with 'sk-'"
  # fi
}

version_compare() {
  local v1 v2 IFS=.
  v1=(${1#v})
  v2=(${2#v})
  for ((i=0; i<${#v1[@]}||i<${#v2[@]};i++)); do
    [[ ${v1[i]:-0} -gt ${v2[i]:-0} ]] && return 0
    [[ ${v1[i]:-0} -lt ${v2[i]:-0} ]] && return 1
  done
  return 0
}

check() {
  command -v "$1" >/dev/null 2>&1 || abort "$1 is required but not installed."
}

# --------- Preflight ---------
check node
check pnpm
check npm

node_version=$(node -v)
version_compare "$node_version" "20.0.0" || abort "Node.js >=20 required."
pnpm_version=$(pnpm -v)
version_compare "$pnpm_version" "10.0.0" || abort "pnpm >=10 required."

# --------- Project Name ---------
read -rp "Enter the project name: " project_name
[[ -z "$project_name" ]] && abort "Project name required."
[[ -e "$project_name" ]] && abort "Directory '$project_name' exists."
validate_project_name "$project_name"

# --------- Create App ---------
echo "🚀 Creating Next.js app..."
pnpm create next-app@latest "$project_name" \
  --app --ts --tailwind --eslint --src-dir --import-alias "@/*" --yes

cd "$project_name"

# Add missing dependencies that are referenced in the code
echo "📦 Installing additional dependencies..."
pnpm add sonner @tanstack/react-query

# --------- Shadcn UI ---------
echo "🎨 Setting up Shadcn UI..."
pnpm dlx shadcn@latest init -y
pnpm dlx shadcn@latest add --all

# --------- Prisma ---------
echo "🗄️  Setting up Prisma..."
read -rp "Enter the database URL (required): " db_url
[[ -z "$db_url" ]] && abort "Database URL required."
validate_database_url "$db_url"

echo "📦 Installing Prisma dependencies..."
pnpm add -D prisma tsx
pnpm add @prisma/client @prisma/extension-accelerate

echo "🔧 Initializing Prisma..."
pnpm dlx prisma init --datasource-provider sqlite

# Overwrite .env with example
cat > .env <<EOF
# For dev use sqlite, for prod swap this to Postgres or other
DATABASE_URL="$db_url"
# This is used for the trpc client to make requests to the server
NEXT_PUBLIC_APP_URL=http://localhost:3000
EOF
cp .env .env.example

# Overwrite starter schema (edit as needed)
echo "📝 Creating Prisma schema..."
cat > prisma/schema.prisma <<EOF
generator client {
  provider = "prisma-client-js"
  previewFeatures = ["clientExtensions"]
}

datasource db {
  provider = "postgres"
  url      = env("DATABASE_URL")
}

model User {
  id    Int     @id @default(autoincrement())
  email String  @unique
  name  String?
  posts Post[]
}

model Post {
  id        Int      @id @default(autoincrement())
  title     String
  content   String?
  published Boolean  @default(false)
  author    User?    @relation(fields: [authorId], references: [id])
  authorId  Int?
}
EOF

echo "🔄 Running Prisma migrations..."
pnpm dlx prisma migrate reset
pnpm dlx prisma migrate dev --name init
pnpm dlx prisma generate

# --------- Seed and DB Utils ---------
echo "🌱 Setting up database utilities..."
mkdir -p prisma src/lib

cat > prisma/seed.ts <<'EOF'
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const user1 = await prisma.user.upsert({
    where: { email: "alice@prisma.io" },
    update: {},
    create: {
      email: "alice@prisma.io",
      name: "Alice",
      posts: {
        create: [
          {
            title: "Hello from Prisma",
            content: "This is a seeded post",
            published: true,
          },
        ],
      },
    },
  });

  const user2 = await prisma.user.upsert({
    where: { email: "bob@prisma.io" },
    update: {},
    create: {
      email: "bob@prisma.io",
      name: "Bob",
      posts: {
        create: [
          {
            title: "Second post",
            content: "Content for second post",
          },
        ],
      },
    },
  });

  console.log({ user1, user2 });
}

main().catch(e => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
EOF

cat > src/lib/db.ts <<'EOF'
import { PrismaClient } from '@prisma/client'
import { withAccelerate } from '@prisma/extension-accelerate'

const globalForPrisma = global as unknown as { prisma?: PrismaClient }

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient().$extends(withAccelerate())

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma
EOF

# --------- TRPC ---------
echo "🔗 Setting up tRPC..."
pnpm add superjson@2.2.2 @trpc/server@11.4.2 @trpc/client@11.4.2 @trpc/tanstack-react-query@11.4.2 @tanstack/react-query@5.80.10 zod

# Create tRPC init file
echo "📁 Creating tRPC files..."
mkdir -p src/trpc
cat > src/trpc/init.ts <<'EOF'
import { initTRPC } from '@trpc/server';
import { cache } from 'react';
import superjson from 'superjson';

export const createTRPCContext = cache(async () => {
    /**
     * @see: https://trpc.io/docs/server/context
     */
    return { userId: 'user_123' };
});

// Avoid exporting the entire t-object
// since it's not very descriptive.
// For instance, the use of a t variable
// is common in i18n libraries.
const t = initTRPC.create({
    /**
     * @see https://trpc.io/docs/server/data-transformers
     */
    transformer: superjson,
});

// Base router and procedure helpers
export const createTRPCRouter = t.router;
export const createCallerFactory = t.createCallerFactory;
export const baseProcedure = t.procedure;
EOF

# Create tRPC router
mkdir -p src/trpc/routers
cat > src/trpc/routers/_app.ts <<'EOF'
import { z } from 'zod';
import { baseProcedure, createTRPCRouter } from '../init';
import { inngest } from '@/inngest/client';

export const appRouter = createTRPCRouter({
  agent: baseProcedure
    .input(
      z.object({
        value: z.string(),
      }),
    )
    .mutation(async ({ input }) => {
      await inngest.send({
        name: "test/agent",
        data: {
          value: input.value,
        },
      });
    }),
  ingestTest: baseProcedure
    .input(
      z.object({
        text: z.string(),
      }),
    )
    .mutation(async ({ input }) => {
      await inngest.send({
        name: "test/hello.world",
        data: {
          email: input.text,
        },
      });
      return {
        status: "success",
      };
    }),
  hello: baseProcedure
    .input(
      z.object({
        text: z.string(),
      }),
    )
    .query((opts) => {
      return {
        greeting: `hello ${opts.input.text}`,
      };
    }),
});

// export type definition of API
export type AppRouter = typeof appRouter;
EOF

# Create tRPC API route
mkdir -p src/app/api/trpc/\[trpc\]
cat > src/app/api/trpc/\[trpc\]/route.ts <<'EOF'
import { fetchRequestHandler } from '@trpc/server/adapters/fetch';
import { createTRPCContext } from '@/trpc/init';
import { appRouter } from '@/trpc/routers/_app';

const handler = (req: Request) =>
  fetchRequestHandler({
    endpoint: '/api/trpc',
    req,
    router: appRouter,
    createContext: createTRPCContext,
  });

export { handler as GET, handler as POST };
EOF

cat > src/trpc/query-client.ts <<'EOF'
import {
  defaultShouldDehydrateQuery,
  QueryClient,
} from '@tanstack/react-query';
import superjson from 'superjson';
export function makeQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: 30 * 1000,
      },
      dehydrate: {
        serializeData: superjson.serialize,
        shouldDehydrateQuery: (query) =>
          defaultShouldDehydrateQuery(query) ||
          query.state.status === 'pending',
      },
      hydrate: {
        deserializeData: superjson.deserialize,
      },
    },
  });
}
EOF

## Wrapper for tanstack and trpc
cat > src/trpc/client.tsx <<'EOF'
'use client';
// ^-- to make sure we can mount the Provider from a server component
import type { QueryClient } from '@tanstack/react-query';
import { QueryClientProvider } from '@tanstack/react-query';
import { createTRPCClient, httpBatchLink } from '@trpc/client';
import { createTRPCContext } from '@trpc/tanstack-react-query';
import { useState } from 'react';
import { makeQueryClient } from './query-client';
import type { AppRouter } from './routers/_app';
import superjson from 'superjson';

export const { TRPCProvider, useTRPC } = createTRPCContext<AppRouter>();
let browserQueryClient: QueryClient;
function getQueryClient() {
  if (typeof window === 'undefined') {
    // Server: always make a new query client
    return makeQueryClient();
  }
  // Browser: make a new query client if we don't already have one
  // This is very important, so we don't re-make a new client if React
  // suspends during the initial render. This may not be needed if we
  // have a suspense boundary BELOW the creation of the query client
  if (!browserQueryClient) browserQueryClient = makeQueryClient();
  return browserQueryClient;
}
function getUrl() {
  const base = (() => {
    if (typeof window !== 'undefined') return '';
    return process.env.NEXT_PUBLIC_APP_URL;
  })();
  return `${base}/api/trpc`;
}
export function TRPCReactProvider(
  props: Readonly<{
    children: React.ReactNode;
  }>,
) {
  // NOTE: Avoid useState when initializing the query client if you don't
  //       have a suspense boundary between this and the code that may
  //       suspend because React will throw away the client on the initial
  //       render if it suspends and there is no boundary
  const queryClient = getQueryClient();
  const [trpcClient] = useState(() =>
    createTRPCClient<AppRouter>({
      links: [
        httpBatchLink({
          transformer: superjson,
          url: getUrl(),
        }),
      ],
    }),
  );
  return (
    <QueryClientProvider client={queryClient}>
      <TRPCProvider trpcClient={trpcClient} queryClient={queryClient}>
        {props.children}
      </TRPCProvider>
    </QueryClientProvider>
  );
}
EOF

cat > src/trpc/server.tsx <<'EOF'
import 'server-only'; // <-- ensure this file cannot be imported from the client
import { createTRPCOptionsProxy } from '@trpc/tanstack-react-query';
import { cache } from 'react';
import { createTRPCContext } from './init';
import { makeQueryClient } from './query-client';
import { appRouter } from './routers/_app';
// IMPORTANT: Create a stable getter for the query client that
//            will return the same client during the same request.
export const getQueryClient = cache(makeQueryClient);
export const trpc = createTRPCOptionsProxy({
  ctx: createTRPCContext,
  router: appRouter,
  queryClient: getQueryClient,
});
// magic that makes direct calls to the server using trpx, without the need for a client (fetch)
export const caller = appRouter.createCaller(createTRPCContext);
EOF

# --------- Inngest ---------
echo "⚡ Setting up Inngest..."
pnpm add inngest@3.39.2
mkdir -p src/inngest
cat > src/inngest/client.ts <<EOF
import { Inngest } from "inngest";

// Create a client to send and receive events
export const inngest = new Inngest({ id: "$project_name" });
EOF

mkdir -p src/app/api/inngest
cat > src/app/api/inngest/route.ts <<'EOF'
import { serve } from "inngest/next";
import { inngest } from "@/inngest/client";
import { agent, helloWorld } from "./functions";

// Create an API that serves zero functions
export const { GET, POST, PUT } = serve({
    client: inngest,
    functions: [
        /* your functions will be passed here later! */
        helloWorld, // <-- This is where you'll always add all your functions
        agent,
    ],
});
EOF

cat > src/app/api/inngest/functions.ts <<'EOF'
import { inngest } from "@/inngest/client";
import { openai, createAgent } from "@inngest/agent-kit";

export const helloWorld = inngest.createFunction(
  { id: "hello-world" },
  { event: "test/hello.world" },
  async ({ event, step }) => {
    await step.sleep("wait-a-moment", "5s");
    await step.sleep("wait-a-moment", "1s");
    return { message: `Hello ${event.data.email}!` };
  },
);

export const agent = inngest.createFunction(
  { id: "agent" },
  { event: "test/agent" },
  async ({ event }) => {

    // Create a new agent with a system prompt (you can add optional tools, too)
    const summariser = createAgent({
      name: "summariser",
      system: "You are an expert summariser.  You summarise in less than 10 words",
      model: openai({ model: "gpt-4o" }),
    });

    // Run the agent with an input.  This automatically uses steps
    // to call your AI model.
    const { output } = await summariser.run(event.data.value);

    return { output };
  },
);

EOF

# --------- OpenAI ---------
echo "🤖 Setting up OpenAI integration..."
read -rp "Enter the OpenAI API key: " openai_api_key
[[ -z "$openai_api_key" ]] && abort "OpenAI API key required."
validate_openai_key "$openai_api_key"
echo "OPENAI_API_KEY=$openai_api_key" >> .env

echo "📦 Installing agent kit..."
pnpm add @inngest/agent-kit@0.8.3

# --------- Next.js Layout ---------
echo "🎨 Setting up Next.js layout and pages..."

cat > src/app/layout.tsx <<'EOF'
import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { TRPCReactProvider } from "@/trpc/client"
import { Toaster } from "sonner";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Create Next App",
  description: "Generated by create next app",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <TRPCReactProvider>
        <html lang="en">
        <body
            className={`${geistSans.variable} ${geistMono.variable} antialiased`}
        >
            {children}
            <Toaster />
        </body>
        </html>
    </TRPCReactProvider>
  );
}
EOF

# --------- Page ---------
cat > src/app/page.tsx <<'EOF'
// --------- Client Side ---------
// "use client"
//import { useTRPC } from "@/trpc/client";
// import { useQuery } from "@tanstack/react-query";

// --------- Server Side ---------
import { caller } from '@/trpc/server';

// --------- Pre fetching data ---------
import { getQueryClient, trpc } from '@/trpc/server';
import { dehydrate, HydrationBoundary } from '@tanstack/react-query';
import Client from '@/app/client';
import { Suspense } from 'react';

export default async function Home() {
  // --------- Server Side ---------
  // const data = await caller.hello({
  //   text: "world"
  // });

  // --------- Client Side ---------
  // const trpc = useTRPC()
  // const { data } = useQuery(
  //   trpc.hello.queryOptions({
  //     text: "world"
  //   })
  // )

  // --------- Pre fetching data ---------
  const queryClient = getQueryClient();
  void queryClient.prefetchQuery(
    trpc.hello.queryOptions({
      text: "world"
    })
  )

  // --------- Server and Client Side ---------
  // return (
  //   <div>
  //     <h1>Hello World</h1>
  //     <p>{data?.greeting}</p>

  //   </div >
  // )

  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      <Suspense fallback={<div>Loading...</div>}>
        <Client />
      </Suspense>
    </HydrationBoundary>
  )
}

// Pre fetching data
// 1. Prefetch the data on the server
// 2. Hydrate the data on the client
// 3. Use the data on the client

// The best of both worlds, almost as fast as a server component, with the client side functionality of the browser

EOF

cat > src/app/client.tsx <<'EOF'
"use client"

import { useTRPC } from "@/trpc/client"
import { useMutation, useSuspenseQuery } from "@tanstack/react-query"
import { Button } from "@/components/ui/button"
import { toast } from "sonner"
import { useState } from "react"
import { Input } from "@/components/ui/input"

// make sure your queryOptions exactly match that from the prefetch query
export default function Client() {
    const [value, setValue] = useState("")
    const trpc = useTRPC()
    const { data } = useSuspenseQuery(
        trpc.hello.queryOptions({
            text: "world"
        })
    )

    const invokeIngestTest = useMutation(trpc.ingestTest.mutationOptions({
        onSuccess: () => toast.success("Ingest test successful"),
        onError: () => toast.error("Ingest test failed")
    }))

    const invokeAgent = useMutation(trpc.agent.mutationOptions({
        onSuccess: () => toast.success("Agent test successful"),
        onError: () => toast.error("Agent test failed")
    }))

    return (
        <div>
            <h1 className="text-2xl font-bold">Demo</h1>
            <Input value={value} onChange={(e) => setValue(e.target.value)} />
            <Button disabled={invokeAgent.isPending} onClick={() => invokeAgent.mutate({ value: value })}>
                {invokeAgent.isPending ? "Agenting..." : "Agent Test"}
            </Button>
            <hr className="my-4" />
            <p>{data?.greeting}</p>
            <hr className="my-4" />
            <Button disabled={invokeIngestTest.isPending} onClick={() => invokeIngestTest.mutate({ text: "world" })}>
                {invokeIngestTest.isPending ? "Ingesting..." : "Ingest Test"}
            </Button>
        </div>
    )
}

EOF

# --------- Git Init ---------
echo "📝 Initializing Git repository..."
git init && git add . && git commit -m "Initial Next.js + Shadcn UI + Prisma starter"

echo ""
echo "🎉 Project $project_name created successfully!"
echo ""
echo "📋 Next steps:"
echo "  cd $project_name"
echo "  pnpm install"
echo "  pnpm run dev"
echo ""
echo "🌱 To seed the database:"
echo "  pnpm exec tsx prisma/seed.ts"
echo ""
echo "📦 Add this to package.json for easier seeding:"
echo "  \"prisma\": {"
echo "    \"seed\": \"tsx prisma/seed.ts\""
echo "  },"
echo ""
echo "⚡ For Inngest development:"
echo "  pnpm dlx inngest-cli@1.8.0 dev"
echo ""
echo "🚀 For Inngest self-hosted server:"
echo "  pnpm dlx inngest-cli@1.8.0 start"
echo ""
echo "📁 Project structure created:"
echo "  ├── src/"
echo "  │   ├── app/           # Next.js App Router"
echo "  │   │   └── page.tsx  # Next.js App Router page"
echo "  │   ├── components/    # Shadcn UI components"
echo "  │   ├── lib/          # Database utilities"
echo "  │   ├── trpc/         # tRPC setup"
echo "  │   └── inngest/      # Inngest functions"
echo "  ├── prisma/           # Database schema & migrations"
echo "  └── .env              # Environment variables"
echo ""
echo "🔧 Technologies included:"
echo "  ✅ Next.js 14 (App Router)"
echo "  ✅ TypeScript"
echo "  ✅ Tailwind CSS"
echo "  ✅ Shadcn UI"
echo "  ✅ tRPC (with SSR support)"
echo "  ✅ Prisma (PostgreSQL)"
echo "  ✅ Inngest (background jobs)"
echo "  ✅ OpenAI integration"
echo ""
