# Feedback Portal

Rails application skeleton for the Feedback Portal (suggestions, voting, comments, roadmap — added in later tasks).

## Stack

- Ruby 3.4.12, Ruby on Rails 8.1.4.1
- PostgreSQL 17 + Active Record
- Server-side rendered ERB, Hotwire (Turbo + Stimulus via importmap)
- Tailwind CSS 4 (`tailwindcss-rails`)
- Built-in Rails Authentication (`bin/rails generate authentication`): sign in, sign out, password reset
- Tests: Minitest (unit/controller) and Playwright (e2e)
- Docker Compose for local development

## Run locally with Docker Compose

Requirements: Docker with Compose v2. Ruby is not needed on the host.

```sh
docker compose up -d --build            # db (PostgreSQL), web (Rails on :3000), css (Tailwind watcher)
docker compose exec web bin/rails db:prepare   # create databases and run migrations
docker compose exec web bin/rails db:seed      # create the test user (idempotent)
```

Open http://localhost:3000. To use another host port: `WEB_PORT=3001 docker compose up -d`.

Stop: `docker compose down`. Reset everything including the database and gem cache: `docker compose down -v`.

### Test user (created by `db/seeds.rb`)

| Email | Password |
| --- | --- |
| `test@example.com` | `password123` |

There is no sign-up yet; users are created via seeds or the Rails console (`docker compose exec web bin/rails console`).

### Password reset in development

Mail is not sent in development; it is written to `tmp/mails/<email>` (e.g. `tmp/mails/test@example.com`). Open the reset link from that file.

## Tests

### Minitest

```sh
docker compose exec web bin/rails test
```

The test database (`feedback_portal_test`) is created/updated automatically by the test run.

### Playwright (e2e smoke)

Runs on the host against the app started with Docker Compose and seeded as above. Requires Node.js 20+.

```sh
npm install                          # installs @playwright/test (.npmrc forces dev deps)
npx playwright install chromium      # first time only
npx playwright test                  # BASE_URL defaults to http://localhost:3000
```

The smoke test (`e2e/smoke.spec.js`) opens the home page as a guest, signs in with the seeded test user and signs out.
Override with `BASE_URL`, `E2E_EMAIL`, `E2E_PASSWORD` if needed.

### Other checks

```sh
docker compose exec web bin/rubocop
docker compose exec web bin/brakeman --quiet --no-pager
```

## Notes

- `Dockerfile.dev` + `compose.yaml` are for development. The generated `Dockerfile` is the Rails production image and is not used by Compose.
- Database connection in Compose is configured with `DATABASE_HOST`, `DATABASE_USERNAME`, `DATABASE_PASSWORD` (see `config/database.yml`); without them Rails uses the local PostgreSQL socket.
