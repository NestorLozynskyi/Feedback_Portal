// Captures screenshots of the running app for every screen/state × role × theme.
// Usage: BASE_URL=http://localhost:3100 node script/screenshots.js [outDir]
// Expects freshly seeded data (bin/rails db:seed:replant). Mutating states are captured last per role.
const { chromium } = require("../node_modules/playwright");
const path = require("node:path");

const BASE = process.env.BASE_URL || "http://localhost:3100";
const OUT = process.argv[2] || path.join(__dirname, "..", "docs", "screenshots", "task-003");
const EMAIL = { user: "maya.chen@example.com", admin: "alex.kim@example.com", restricted: "jordan.lee@example.com" };
const KEY = new Set(["board", "suggestion", "roadmap", "form", "signin"]);
const submit = (sel) => async (p) => { await p.evaluate(() => document.activeElement && document.activeElement.blur()); await p.waitForTimeout(100); await p.locator(sel).first().click(); await p.waitForTimeout(300); };
const fillSubmit = (fields, sel) => async (p) => { for (const [k, v] of fields) await p.fill(k, v); await submit(sel)(p); };
const click = (sel) => async (p) => { await p.locator(sel).first().click(); await p.waitForTimeout(350); };

const SCREENS = {
  guest: [
    ["board", "/", null, true],
    ["board-sorted-votes", "/?sort=votes"],
    ["suggestion", "/suggestions/1", null, true],
    ["suggestion-hidden-unavailable", "/suggestions/7"],
    ["roadmap", "/roadmap", null, true],
    ["form-signin-prompt", "/suggestions/new", null, "form"],
    ["signin", "/session/new", null, true],
    ["signin-field-errors", "/session/new", fillSubmit([["#email", "maya.chen@"]], "#signin-form button[type=submit]")],
    ["signin-wrong-password", "/session/new", fillSubmit([["#email", "maya.chen@example.com"], ["#password", "wrongpass"]], "#signin-form button[type=submit]")],
    ["signin-reason-vote", "/session/new?reason=vote"],
    ["signup", "/signup"],
    ["signup-field-errors", "/signup", fillSubmit([["#email", "maya.chen@example.com"], ["#password", "1234"]], "#signup-form button[type=submit]")],
    ["signup-server-errors", "/signup", async (p) => { await p.evaluate(() => document.querySelector("#signup-form").removeAttribute("data-controller"));
      await fillSubmit([["#name", "Maya"], ["#email", "maya.chen@example.com"], ["#password", "12345678"]], "#signup-form button[type=submit]")(p); }],
    ["forgot", "/passwords/new"],
    ["forgot-field-error", "/passwords/new", fillSubmit([["#email", "maya.chen@example"]], "#forgot-form button[type=submit]")],
    ["forgot-sent", "/passwords/new", fillSubmit([["#email", "maya.chen@example.com"]], "#forgot-form button[type=submit]")],
    ["reset-expired", "/passwords/expired-token/edit"],
    ["admin-signin-required", "/admin/categories"],
  ],
  user: [
    ["board", "/", null, true],
    ["board-sorted-votes", "/?sort=votes"],
    ["suggestion-not-voted", "/suggestions/1", null, "suggestion"],
    ["suggestion-voted", "/suggestions/2"],
    ["suggestion-own", "/suggestions/3"],
    ["suggestion-own-hidden", "/suggestions/7"],
    ["suggestion-comment-edit", "/suggestions/1", click("#comment-3 a.link-btn")],
    ["suggestion-delete-dialog", "/suggestions/3", click(".owner-actions button")],
    ["roadmap", "/roadmap", null, true],
    ["form", "/suggestions/new", null, true],
    ["form-validation-errors", "/suggestions/new", submit("#suggestion-form button[type=submit]")],
    ["form-edit", "/suggestions/3/edit"],
    ["form-edit-hidden", "/suggestions/7/edit"],
    ["admin-categories-no-access", "/admin/categories"],
    ["admin-users-no-access", "/admin/users"],
  ],
  admin: [
    ["board", "/", null, true],
    ["suggestion-moderation", "/suggestions/1", null, "suggestion"],
    ["suggestion-under-review", "/suggestions/9"],
    ["suggestion-hidden", "/suggestions/7"],
    ["roadmap", "/roadmap", null, true],
    ["form", "/suggestions/new", null, true],
    ["admin-categories", "/admin/categories"],
    ["admin-categories-rename", "/admin/categories", click("a.link-btn")],
    ["admin-categories-add-error", "/admin/categories", fillSubmit([["#new-cat", "Security"]], "#add-cat-form button[type=submit]")],
    ["admin-categories-delete-dialog", "/admin/categories", click(".cat-actions button")],
    ["admin-users", "/admin/users"],
    ["admin-users-block-dialog", "/admin/users", click("button.btn-danger-outline")],
  ],
  restricted: [
    ["board", "/", null, true],
    ["suggestion", "/suggestions/1", null, true],
    ["suggestion-own", "/suggestions/5"],
    ["roadmap", "/roadmap", null, true],
    ["form-unavailable", "/suggestions/new", null, "form"],
  ],
};

(async () => {
  const browser = await chromium.launch();
  const only = process.env.ONLY_ROLE;
  for (const [role, screens] of Object.entries(SCREENS)) {
    if (only && only !== role) continue;
    for (const theme of ["light", "dark"]) {
      const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 }, colorScheme: theme });
      await ctx.addInitScript((t) => { try { localStorage.setItem("fp-theme", t) } catch (e) {} }, theme);
      const page = await ctx.newPage();
      if (EMAIL[role]) {
        await page.goto(BASE + "/session/new");
        await page.fill("#email", EMAIL[role]); await page.fill("#password", "password123");
        await page.click("#signin-form button[type=submit]"); await page.waitForURL(BASE + "/");
      }
      for (const [name, url, action, key] of screens) {
        const widths = key ? [1440, 768, 375] : [1440];
        for (const w of widths) {
          await page.setViewportSize({ width: w, height: 900 });
          await page.goto(BASE + url);
          await page.evaluate(() => document.querySelectorAll(".toast").forEach((t) => t.remove()));
          if (action) await action(page);
          await page.evaluate(() => window.scrollTo(0, 0));
          await page.evaluate(() => document.querySelectorAll(".toast").forEach((t) => t.remove()));
          await page.screenshot({ path: path.join(OUT, `${name}--${role}--${theme}--${w}.png`), fullPage: true });
          if (action) await page.keyboard.press("Escape");
        }
      }
      await ctx.close();
    }
  }
  await browser.close();
})();
