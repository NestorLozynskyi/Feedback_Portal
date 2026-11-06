// @ts-check
const { test, expect } = require("@playwright/test");
const { PASSWORD } = require("./helpers");

test("a guest who votes is sent to sign in and comes back", async ({ page }) => {
  await page.goto("/");
  const row = page.locator(".s-row", { hasText: "Export a board to CSV" });
  await row.locator(".vote").click();
  await expect(page.getByRole("heading", { name: "Sign in" })).toBeVisible();
  await expect(page.locator(".notice-info")).toHaveText("Sign in to upvote suggestions.");

  await page.getByLabel("Email").fill("maya.chen@example.com");
  await page.locator("#password").fill(PASSWORD);
  await page.getByRole("button", { name: "Sign in" }).click();
  await expect(page.getByRole("heading", { level: 1 })).toHaveText("Export a board to CSV");
  await expect(page.locator(".vote--large")).toContainText("Upvote");
});

test("guest sees sign-in prompts for comment and create; hidden suggestion is unavailable", async ({ page }) => {
  await page.goto("/suggestions/1");
  await expect(page.locator(".composer-gate")).toContainText("Sign in to join the discussion.");
  await page.goto("/suggestions/new");
  await expect(page.getByRole("heading", { name: "Sign in to share a suggestion" })).toBeVisible();
  await page.goto("/suggestions/7");
  await expect(page.getByRole("heading", { name: "This suggestion isn’t available" })).toBeVisible();
  await page.goto("/");
  await expect(page.getByText("Pin a comment to the top of a task")).toHaveCount(0);
});

test("theme toggle switches and remembers the theme", async ({ page }) => {
  await page.emulateMedia({ colorScheme: "light" });
  await page.goto("/");
  const html = page.locator("html");
  await expect(html).toHaveAttribute("data-theme", "light");
  const toggle = page.getByRole("button", { name: "Switch to dark theme" });
  await toggle.click();
  await expect(html).toHaveAttribute("data-theme", "dark");
  await expect(page.getByRole("button", { name: "Switch to light theme" })).toBeVisible();
  const bg = await page.evaluate(() => getComputedStyle(document.body).backgroundColor);
  expect(bg).toBe("rgb(9, 9, 11)");
  await page.goto("/roadmap");
  await expect(html).toHaveAttribute("data-theme", "dark");
  await page.getByRole("button", { name: "Switch to light theme" }).click();
  await page.reload();
  await expect(html).toHaveAttribute("data-theme", "light");
});
