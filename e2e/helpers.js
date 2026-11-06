const { expect } = require("@playwright/test");

const PASSWORD = "password123";
const USERS = {
  admin: "alex.kim@example.com",
  maya: "maya.chen@example.com",
  jordan: "jordan.lee@example.com",
  sam: "sam.patel@example.com",
};

async function signIn(page, who) {
  await page.goto("/session/new");
  await page.getByLabel("Email").fill(USERS[who] || who);
  await page.locator("#password").fill(PASSWORD);
  await page.getByRole("button", { name: "Sign in" }).click();
  await expect(page.locator(".account-btn")).toBeVisible();
}

async function signOut(page) {
  await page.locator(".account-btn").click();
  await page.getByRole("button", { name: "Sign out" }).click();
  await expect(page.getByRole("link", { name: "Sign in" }).first()).toBeVisible();
}

async function confirmDialog(page, label) {
  const dialog = page.locator("#confirm-dialog");
  await expect(dialog).toBeVisible();
  await dialog.getByRole("button", { name: label }).click();
}

async function openSuggestion(page, title) {
  await page.goto("/");
  await page.getByRole("link", { name: title, exact: true }).click();
  await expect(page.getByRole("heading", { level: 1, name: title })).toBeVisible();
}

module.exports = { PASSWORD, USERS, signIn, signOut, confirmDialog, openSuggestion };
