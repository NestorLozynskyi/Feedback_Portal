// @ts-check
const { test, expect } = require("@playwright/test");

// Seeded test user (db/seeds.rb).
const EMAIL = process.env.E2E_EMAIL || "test@example.com";
const PASSWORD = process.env.E2E_PASSWORD || "password123";

test("guest opens home, signs in with seeded user, signs out", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByTestId("auth-status")).toContainText("guest");

  await page.getByRole("main").getByRole("link", { name: "Sign in" }).click();
  await expect(page.getByRole("heading", { name: "Sign in" })).toBeVisible();

  await page.getByPlaceholder("Enter your email address").fill(EMAIL);
  await page.getByPlaceholder("Enter your password").fill(PASSWORD);
  await page.getByRole("button", { name: "Sign in" }).click();

  await expect(page).toHaveURL("/");
  await expect(page.getByTestId("auth-status")).toContainText(`Signed in as ${EMAIL}`);

  await page.getByRole("button", { name: "Sign out" }).click();
  await expect(page.getByRole("heading", { name: "Sign in" })).toBeVisible();

  await page.goto("/");
  await expect(page.getByTestId("auth-status")).toContainText("guest");
});
