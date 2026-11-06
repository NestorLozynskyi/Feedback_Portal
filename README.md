# Feedback Portal

Public feedback portal: people share suggestions (Idea, Feature Request, Bug Report), upvote and comment;
the admin moderates, manages categories and users, and a public Roadmap shows Planned / In Progress / Completed.

## Stack

- Ruby 3.4.12, Ruby on Rails 8.1.4.1, PostgreSQL 17 + Active Record
- Server-side rendered ERB, Hotwire (Turbo Drive/Frames/Streams + Stimulus via importmap)
- Tailwind CSS 4 (`tailwindcss-rails`); design tokens and components from the approved mockups live in
  `app/assets/tailwind/application.css`; light/dark theme via `<html data-theme>` (Tailwind `dark:` follows it)
- Built-in Rails Authentication (sign in/out, password reset) + self sign-up
- Tests: Minitest (models, controllers) and Playwright (e2e)
- Docker Compose for local development

## Run locally with Docker Compose

Requirements: Docker with Compose v2. Ruby is not needed on the host.

```sh
docker compose up -d --build                   # db (PostgreSQL), web (Rails on :3000), css (Tailwind watcher)
docker compose exec web bin/rails db:prepare   # create databases and run migrations
docker compose exec web bin/rails db:seed      # demo data (idempotent)
```

Open http://localhost:3000. Other host port: `WEB_PORT=3001 docker compose up -d`.
Reset the demo data: `docker compose exec web bin/rails db:seed:replant`.
Stop: `docker compose down`; remove the database and gem cache too: `docker compose down -v`.

### Configuration

| ENV | Default | Purpose |
| --- | --- | --- |
| `PRODUCT_NAME` | `Feedback Portal` | Product name in the header, page titles and texts |
| `ADMIN_EMAIL` / `ADMIN_PASSWORD` / `ADMIN_NAME` | `alex.kim@example.com` / `password123` / `Alex Kim` | The single admin, created by `db:seed` |
| `SIGNIN_RATE_LIMIT` | `10` | Sign-in / reset requests per 3 minutes per IP |

Set them in `compose.yaml` (`x-app.environment`) or pass them to the command, e.g.
`docker compose exec -e ADMIN_EMAIL=me@example.com -e ADMIN_PASSWORD=secret123 web bin/rails db:seed`.

### Admin

There is exactly one admin (enforced by a unique partial index on `users.admin`) and no UI to assign it.
The admin is created or updated by `db:seed` from the `ADMIN_*` variables above. To make an existing user the
admin instead, use the console: `docker compose exec web bin/rails runner 'User.find_by!(email_address: "x@example.com").update!(admin: true)'`
(only if no other admin exists).

### Seeded accounts (password `password123`)

| Email | Role |
| --- | --- |
| `alex.kim@example.com` | Admin |
| `maya.chen@example.com` | Member (author of a hidden suggestion and a hidden comment) |
| `jordan.lee@example.com` | Blocked member |
| `priya.nair@example.com`, `sam.patel@example.com`, `elena.rossi@example.com`, `tom.becker@example.com`, `aiko.tanaka@example.com` | Members |

Seeds also create categories UI/UX, Performance, Security, Integrations and 12 suggestions covering all five
statuses, including a hidden one, with votes and comments.

### Password reset in development

Mail is not sent in development; it is written to `tmp/mails/<email>`. Open the reset link from that file.

## Tests

### Minitest

```sh
docker compose exec web bin/rails test
```

### Playwright (e2e)

E2E runs against a separate `e2e` Compose service with its own database (`feedback_portal_e2e`, port 3100);
the global setup resets it with `db:seed:replant` before each run. Requires Node.js 20+ on the host.

```sh
docker compose --profile e2e up -d e2e   # first time: also creates and migrates its database
npm install                              # installs @playwright/test (.npmrc forces dev deps)
npx playwright install chromium          # first time only
npx playwright test
```

`BASE_URL` (default `http://localhost:3100`) and `E2E_RESET_CMD` (empty string skips the reset) can be overridden.

### Other checks

```sh
docker compose exec web bin/rubocop
docker compose exec web bin/brakeman --quiet --no-pager
```

### Screenshots

`node script/screenshots.js` captures every screen/state × role × theme from the e2e instance into
`docs/screenshots/task-003/` (reseed first). `script/screenshots_extra.js` adds the empty board and reset-password states.

## Notes

- `Dockerfile.dev` + `compose.yaml` are for development. The generated `Dockerfile` is the Rails production image and is not used by Compose.
- Database connection in Compose: `DATABASE_HOST`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`, `DATABASE_NAME` (see `config/database.yml`).
