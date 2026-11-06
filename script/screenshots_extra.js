// Extra screenshot states: `reset <token>` (reset password form/errors/success) and `empty` (empty board; delete suggestions first).
const { chromium } = require("../node_modules/playwright");
const BASE = "http://localhost:3100", OUT = require("node:path").join(__dirname, "..", "docs", "screenshots", "task-003");
const EMAIL = { user: "maya.chen@example.com", restricted: "jordan.lee@example.com" };
const [mode, token] = process.argv.slice(2);
(async () => {
  const b = await chromium.launch();
  for (const theme of ["light", "dark"]) {
    if (mode === "empty") {
      for (const role of ["guest", "user", "restricted"]) {
        const c = await b.newContext({ viewport: { width: 1440, height: 900 }, colorScheme: theme });
        await c.addInitScript((t) => localStorage.setItem("fp-theme", t), theme);
        const p = await c.newPage();
        if (EMAIL[role]) { await p.goto(BASE + "/session/new"); await p.fill("#email", EMAIL[role]); await p.fill("#password", "password123"); await p.click("#signin-form button[type=submit]"); await p.waitForURL(BASE + "/"); }
        await p.goto(BASE + "/"); await p.evaluate(() => document.querySelectorAll(".toast").forEach((t) => t.remove()));
        await p.screenshot({ path: `${OUT}/board-empty--${role}--${theme}--1440.png`, fullPage: true });
        await c.close();
      }
    } else {
      const c = await b.newContext({ viewport: { width: 1440, height: 900 }, colorScheme: theme });
      await c.addInitScript((t) => localStorage.setItem("fp-theme", t), theme);
      const p = await c.newPage();
      await p.goto(`${BASE}/passwords/${token}/edit`);
      await p.screenshot({ path: `${OUT}/reset--guest--${theme}--1440.png`, fullPage: true });
      await p.fill("#password", "abc"); await p.fill("#password_confirmation", "abcd");
      await p.click("#reset-form button[type=submit]"); await p.waitForTimeout(250);
      await p.screenshot({ path: `${OUT}/reset-field-errors--guest--${theme}--1440.png`, fullPage: true });
      if (theme === "dark") {
        await p.goto(`${BASE}/passwords/${token}/edit`);
        await p.fill("#password", "password123"); await p.fill("#password_confirmation", "password123");
        await p.click("#reset-form button[type=submit]"); await p.waitForTimeout(400);
        await p.screenshot({ path: `${OUT}/reset-success--guest--dark--1440.png`, fullPage: true });
        await p.evaluate(() => { document.documentElement.dataset.theme = "light" });
        await p.screenshot({ path: `${OUT}/reset-success--guest--light--1440.png`, fullPage: true });
      }
      await c.close();
    }
  }
  await b.close();
})();
