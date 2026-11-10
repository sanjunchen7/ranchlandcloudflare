# Ranchland Villa Motel

A full-stack public motel website and reservation management system for Ranchland Villa Motel, 2379 Nicola Ave, Merritt, BC. The application runs on **Cloudflare Workers + Workers Assets**, with React/Vite, Hono, tRPC, Drizzle ORM, the existing MySQL database through Hyperdrive, R2 media storage and Cloudflare Email Service.

## Included functionality

- Mobile-first public site: Home, Rooms, Availability / Reservation Request, Contact and FAQ.
- Five public room types and 17 public rooms; Room 13 remains internal.
- Reservation Requests are not confirmations. Staff authentication, ADMIN / FRONT_DESK permissions, manual guarantees, holds, confirmation, check-in, checkout and no-show workflows remain database-backed.
- Timed room holds, maintenance blocks, per-night rates, tax rules, versioned price snapshots and `UNIQUE(room_id, stay_date)` inventory protection.
- JPEG / PNG / WebP magic-byte and dimension validation, authenticated R2 uploads, public/internal media authorization, covers, ordering, reference checks and deletion.
- Email outbox with delivery status, deduplication, failure recording and resend. Email failure does not roll back a reservation.
- Installable PWA, SEO metadata, sitemap and robots.txt. `/admin/...` direct loads use the React SPA fallback.

## Runtime architecture

| Concern | Implementation |
| --- | --- |
| Public website and Admin UI | React 19 + Vite static assets on Cloudflare |
| Worker entry | `api/boot.ts`, Hono `fetch` handler |
| API | Existing Hono + tRPC routers and validation |
| Database | Existing MySQL; Worker requests use `HYPERDRIVE` |
| Photos | `MEDIA_BUCKET` R2 binding; database stores keys and metadata only |
| Transactional email | `EMAIL` Cloudflare Email Service binding |
| Staff sessions | Random tokens hashed in MySQL; HttpOnly/Secure cookies |
| Logs | Structured console logs and Workers Observability; no filesystem writes |

Each Worker request gets one MySQL connection through the request-scoped runtime adapter. Existing services continue to call `getDb()`, and the connection closes after the response. Local migration and seed scripts use `DATABASE_URL` directly.

## Prerequisites

- Node.js 22 or newer and npm.
- A MySQL database reachable by Cloudflare Hyperdrive.
- A Cloudflare account with Workers, Hyperdrive, R2 and Email Service access.
- A verified/onboarded sender domain for real email delivery.

## Local development

1. Install dependencies and prepare local variables:

   ```bash
   npm install
   cp .env.example .env
   cp .dev.vars.example .dev.vars
   ```

2. Put the direct MySQL URL in both files. `.env` is for Drizzle/seed scripts; `.dev.vars` is for the local Worker. Neither file is committed.
3. Create the required Cloudflare resources below and replace the Hyperdrive placeholder under `env.production` in `wrangler.jsonc`. Local development uses `.dev.vars` and direct MySQL; `npm run deploy` selects the production environment and its Hyperdrive binding.
4. For a **new empty database**, run:

   ```bash
   npm run db:migrate
   ```

   For an **existing Ranchland database**, back it up and run `npm run db:push` instead. Review every proposed change before accepting it; do not replay the baseline `0000` migration against existing tables. Never use force or drop tables to resolve a migration problem.

5. Set strong `ADMIN_INITIAL_PASSWORD` and `FRONTDESK_INITIAL_PASSWORD` values in `.env`, then seed:

   ```bash
   npm run db:seed
   ```

   Passwords are required only when the corresponding account does not already exist. Existing password hashes are not overwritten.
6. Start the Cloudflare Vite development runtime:

   ```bash
   npm run dev
   ```

   The app listens on `http://localhost:3000`. Wrangler simulates the email binding locally by default and logs rather than sends real email. To test real delivery, deliberately set `"remote": true` on the `send_email` binding after configuring Email Service.

## Cloudflare resource setup

Log in and create R2 and Hyperdrive:

```bash
npx wrangler login
npx wrangler r2 bucket create ranchland-villa-media
npx wrangler hyperdrive create ranchland-villa-mysql --connection-string="mysql://USER:PASSWORD@HOST:3306/DATABASE"
```

Copy the returned Hyperdrive ID into `wrangler.jsonc`. Do not commit the MySQL connection string. Hyperdrive stores the production database credentials; no database password is needed in the frontend or repository.

The configured bindings are:

- `HYPERDRIVE` — existing MySQL connection.
- `MEDIA_BUCKET` — R2 bucket `ranchland-villa-media`.
- `EMAIL` — transactional email sender.
- `EMAIL_FROM` — non-secret sender address variable; change it to an address on the onboarded domain.

In the Cloudflare dashboard, onboard the sending domain under **Email Service → Email Sending**, configure its DNS records, and verify the sender. If `EMAIL` is unavailable, the application keeps messages honestly marked `QUEUED`; it never reports an unsent message as sent.

No Wrangler secret is required for the current production database path because Hyperdrive owns those credentials. If a future integration needs a secret, use `npx wrangler secret put NAME`; never put it in `wrangler.jsonc`, `.env.example`, source code or client variables.

## Verify and deploy

```bash
npm run check
npm run test
npm run build
npm run deploy
```

`npm run build` produces the Worker and static client under `dist/`. There is no Node production server, `dist/boot.js`, Sharp vendoring or Docker startup step. Deployment requires the real Hyperdrive ID and the resources above. Publishing/deploying from this repository does not run database migrations automatically; run the appropriate reviewed migration step first.

After deployment, attach the motel's custom domain to the Worker in Cloudflare. Verify at minimum:

1. Public pages and direct `/admin/login` / `/admin/reservations` loads.
2. Reservation Request persistence, idempotency and email outbox records.
3. Admin login/logout, expired sessions, 401/403 authorization and role restrictions.
4. Room/rate/tax/settings changes appearing on the public site from the same database.
5. Hold, maintenance and confirmation conflict protection, including concurrent confirmation.
6. Public photo rendering, private-photo rejection, upload, cover/reorder and deletion.
7. Confirmation, updated confirmation, failed email records and resend.

## Media migration and limits

New uploads go directly to R2 and keep the original JPEG / PNG / WebP. The Worker validates magic bytes and image dimensions without native libraries. Browser code and responsive layouts use the original image; server-generated thumbnail/medium/large variants are no longer created. Existing `variants` metadata remains readable as a fallback, but old third-party object-storage objects are **not copied automatically**. Back up and copy those objects to the same R2 keys, or re-upload the photos, before removing the old storage service.

## Security notes

- Never enter or store a full card number, CVV or CVC. Only brand, last four digits and a provider reference are supported; no automatic card charging occurs.
- Staff sessions and rate limits are shared through MySQL rather than isolate-local memory. Rate-limit keys are hashed.
- Mutations are origin-checked; public requests include validation and a honeypot.
- R2 media is served through `/api/media/*`; internal images require a valid staff session and unauthorized objects return 404.
- Logging is structured and scrubbed, with no production filesystem dependency.

## Tests

`npm run test` covers half-open date overlap, same-day checkout/arrival, guest validation, uncapped infants, motel-timezone dates, early check-in limits, legal state transitions, money rounding, card-last-four validation, base64 validation and JPEG/PNG/WebP metadata parsing.

A build and unit-test pass does not prove external MySQL, Hyperdrive, R2 or Email Service connectivity. Those require the real Cloudflare resources and the post-deployment checks above.

## Assets and licenses

Inter and Space Grotesk are bundled through Fontsource under the SIL Open Font License. Lucide icons are ISC-licensed. Included placeholder illustrations are explicitly non-photographic placeholders, not representations of actual motel rooms.
