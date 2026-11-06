// @ts-check
const { test, expect } = require("@playwright/test");
const { signIn, signOut, confirmDialog, openSuggestion } = require("./helpers");

test("admin changes status and the suggestion appears on the roadmap", async ({ page }) => {
  await page.goto("/roadmap");
  await expect(page.locator(".rm-card", { hasText: "Single sign-on with Okta" })).toHaveCount(0);

  await signIn(page, "admin");
  await openSuggestion(page, "Single sign-on with Okta");
  await page.locator("#status-select").selectOption({ label: "In Progress" });
  await page.getByRole("button", { name: "Update status" }).click();
  await expect(page.locator(".toast").last()).toContainText("Status changed to In Progress.");
  await expect(page.locator(".side-card .badge").first()).toHaveText("In Progress");

  await page.getByRole("link", { name: "View the roadmap" }).click();
  await expect(page.locator('#col-in-progress .rm-card', { hasText: "Single sign-on with Okta" })).toBeVisible();
});

test("admin hides and unhides a suggestion", async ({ browser }) => {
  const admin = await (await browser.newContext()).newPage();
  const guest = await (await browser.newContext()).newPage();
  await signIn(admin, "admin");
  await openSuggestion(admin, "Bulk edit due dates");
  await admin.getByRole("button", { name: "Hide suggestion" }).click();
  await expect(admin.locator(".notice-hidden")).toContainText("Hidden by moderator");
  await expect(admin.getByRole("button", { name: "Unhide suggestion" })).toBeVisible();

  await guest.goto("/");
  await expect(guest.getByText("Bulk edit due dates")).toHaveCount(0);
  await guest.goto("/roadmap");
  await expect(guest.getByText("Bulk edit due dates")).toHaveCount(0);

  await admin.getByRole("button", { name: "Unhide suggestion" }).click();
  await expect(admin.locator(".notice-hidden")).toHaveCount(0);
  await guest.goto("/");
  await expect(guest.getByRole("link", { name: "Bulk edit due dates" })).toBeVisible();
});

test("admin hides a comment and blocks a user, who then sees the banner and no actions", async ({ browser }) => {
  const admin = await (await browser.newContext()).newPage();
  await signIn(admin, "admin");
  await openSuggestion(admin, "Board takes 8–10 seconds to load with about 500 tasks");
  const comment = admin.locator(".comment", { hasText: "Seeing the same with about 400 tasks" });
  await comment.getByRole("button", { name: "Hide" }).click();
  await expect(admin.locator(".comment", { hasText: "Seeing the same" })).toContainText("Hidden by moderator");
  await admin.locator(".comment", { hasText: "Seeing the same" }).getByRole("button", { name: "Unhide" }).click();
  await expect(admin.locator(".comment", { hasText: "Seeing the same" })).not.toContainText("Hidden by moderator");

  await admin.getByRole("link", { name: "Users" }).click();
  await admin.getByRole("button", { name: "Block Sam Patel" }).click();
  await confirmDialog(admin, "Block user");
  await expect(admin.locator(".toast").last()).toContainText("Sam Patel is blocked.");
  await expect(admin.getByRole("button", { name: "Unblock Sam Patel" })).toBeVisible();

  const sam = await (await browser.newContext()).newPage();
  await signIn(sam, "sam");
  await expect(sam.locator(".banner")).toContainText("Your account is restricted");
  await expect(sam.getByRole("button", { name: "New suggestion" })).toBeDisabled();
  await openSuggestion(sam, "Export a board to CSV");
  await expect(sam.locator(".vote--large")).toBeDisabled();
  await expect(sam.locator(".notice-warn")).toContainText("You can’t comment while your account is restricted.");
  await openSuggestion(sam, "Board takes 8–10 seconds to load with about 500 tasks");
  await expect(sam.locator(".owner-actions").getByRole("button", { name: "Edit" })).toBeDisabled();
  await expect(sam.locator(".owner-actions").getByRole("button", { name: "Delete" })).toBeDisabled();

  await admin.getByRole("button", { name: "Unblock Sam Patel" }).click();
  await expect(admin.getByRole("button", { name: "Block Sam Patel" })).toBeVisible();
  await sam.reload();
  await expect(sam.locator(".banner")).toHaveCount(0);
  await expect(sam.locator(".owner-actions").getByRole("link", { name: "Edit" })).toBeVisible();
});

test("admin manages categories and deletes one that has suggestions", async ({ page }) => {
  await signIn(page, "admin");
  await page.getByRole("link", { name: "Categories" }).click();
  await expect(page.getByRole("heading", { level: 1, name: "Categories" })).toBeVisible();

  await page.getByLabel("New category").fill("ui/ux");
  await page.getByRole("button", { name: "Add category" }).click();
  await expect(page.locator("#new-cat-error")).toContainText("A category with this name already exists.");

  await page.getByLabel("New category").fill("Mobile");
  await page.getByRole("button", { name: "Add category" }).click();
  await expect(page.locator(".toast").last()).toContainText("Category “Mobile” added.");
  await expect(page.locator(".cat-name", { hasText: "Mobile" })).toBeVisible();

  await page.getByRole("link", { name: "Rename Mobile" }).click();
  await page.locator("#rename-cat").fill("Mobile apps");
  await page.getByRole("button", { name: "Save" }).click();
  await expect(page.locator(".cat-name", { hasText: "Mobile apps" })).toBeVisible();

  await page.getByRole("button", { name: "Delete Mobile apps" }).click();
  await expect(page.locator("#dlg-body")).toHaveText("No suggestions use this category. This can’t be undone.");
  await confirmDialog(page, "Delete category");
  await expect(page.locator(".cat-name", { hasText: "Mobile apps" })).toHaveCount(0);

  const perf = page.locator(".cat-list li", { hasText: "Performance" });
  await expect(perf.locator(".cat-count")).toHaveText("2 suggestions");
  await page.getByRole("button", { name: "Delete Performance" }).click();
  await expect(page.locator("#dlg-body")).toContainText("2 suggestions use this category. They stay on the board and show as Uncategorized.");
  await confirmDialog(page, "Delete category");
  await expect(page.locator(".toast").last()).toContainText("Category “Performance” deleted.");

  await page.goto("/");
  const row = page.locator(".s-row", { hasText: "Offline mode for the desktop app" });
  await expect(row).toContainText("Uncategorized");
  await signOut(page);
});

test("non-admin sees no access on admin pages", async ({ page }) => {
  await signIn(page, "maya");
  await page.goto("/admin/categories");
  await expect(page.getByRole("heading", { name: "You don’t have access to this page" })).toBeVisible();
  await page.goto("/admin/users");
  await expect(page.getByRole("heading", { name: "You don’t have access to this page" })).toBeVisible();
});
