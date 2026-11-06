const { execSync } = require("node:child_process");

// Reset the e2e database to the seed data. Override with E2E_RESET_CMD (empty string skips the reset).
module.exports = async () => {
  const cmd = process.env.E2E_RESET_CMD ?? "docker compose exec -T e2e bin/rails db:seed:replant";
  if (cmd) execSync(cmd, { stdio: "inherit", cwd: __dirname + "/.." });
};
