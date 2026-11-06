// @ts-check
const { defineConfig, devices } = require("@playwright/test");

// E2E runs against the separate `e2e` Compose service (own database), see README:
//   docker compose --profile e2e up -d e2e && npx playwright test
// global-setup resets its data with seeds before the run.
module.exports = defineConfig({
  testDir: "./e2e",
  globalSetup: require.resolve("./e2e/global-setup.js"),
  fullyParallel: false,
  workers: 1,
  retries: 0,
  reporter: "list",
  timeout: 60_000,
  use: {
    baseURL: process.env.BASE_URL || "http://localhost:3100",
    trace: "retain-on-failure",
  },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
});
