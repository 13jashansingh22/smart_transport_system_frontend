# Backend API

Minimal Node.js + Express backend starter for Smart Transport System.

## Features

- `GET /health` health check endpoint
- `GET /` basic service info
- Environment-based CORS allowlist
- Built-in test using Node test runner + Supertest

## Project Structure

- `src/app.js` - Express app factory and routes
- `src/server.js` - server bootstrap
- `test/health.test.js` - smoke test for `/health`

## Setup

```bash
npm install
```

## Run

```bash
npm run dev
```

## Deploy on Vercel

`vercel.json` routes all requests to `api/index.js`.

Vercel project settings:

- Framework Preset: `Other`
- Root Directory: `backend` (if deploying from monorepo)
- Build Command: leave empty
- Output Directory: leave empty

After deploy:

- `GET /health` should return API status JSON.

## Test

```bash
npm test
```

## Environment Variables

Copy `.env.example` to `.env` and update values as needed.

- `PORT` - API port (default `3000`)
- `NODE_ENV` - environment name
- `ALLOWED_ORIGINS` - comma-separated CORS allowlist
