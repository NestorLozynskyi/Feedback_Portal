// @ts-check
const { test, expect } = require("@playwright/test");
const { confirmDialog, signOut } = require("./helpers");

test("sign up → create suggestion → vote and unvote → comment → edit and delete own content", async ({ page }) => {
  const stamp = Date.now();
  const email = `new.user.${stamp}@example.com`;
  const title = `Calendar view for tasks ${stamp}`;

  await page.goto("/");
  await page.getByRole("link", { name: "Sign up" }).click();
  await page.getByLabel("Name").fill("Nora Quinn");
  await page.getByLabel("Email").fill(email);
  await page.locator("#password").fill("longpassword");
  await page.getByRole("button", { name: "Create account" }).click();
  await expect(page.locator(".toast")).toContainText("Welcome! Your account is ready.");
  await expect(page.locator(".account-name")).toHaveText("Nora");

  // Create
  await page.getByRole("link", { name: "New suggestion" }).click();
  await page.getByRole("button", { name: "Publish suggestion" }).click();
  await expect(page.locator(".error-summary")).toContainText("There are 4 problems to fix");
  await page.getByLabel("Title").fill(title);
  await expect(page.locator("#title-count")).toHaveText(`${title.length}/120`);
  await page.locator("label.choice", { hasText: "Feature Request" }).click();
  await page.getByLabel("Category").selectOption({ label: "UI/UX" });
  await page.getByLabel("Description").fill("A month view that shows tasks by due date would help planning.");
  await page.getByRole("button", { name: "Publish suggestion" }).click();
  await expect(page.locator(".toast")).toContainText("Suggestion published. Its status is Under Review.");
  await expect(page.getByRole("heading", { level: 1 })).toHaveText(title);
  await expect(page.locator(".side-card .badge")).toHaveText("Under Review");

  // Vote and remove the vote (Turbo Stream)
  const vote = page.locator(".vote--large");
  await expect(vote).toContainText("Upvote");
  await expect(vote.locator(".vote-count")).toHaveText("0");
  await vote.click();
  await expect(page.locator(".vote--large")).toContainText("Upvoted");
  await expect(page.locator(".vote--large .vote-count")).toHaveText("1");
  await page.locator(".vote--large").click();
  await expect(page.locator(".vote--large")).toContainText("Upvote");
  await expect(page.locator(".vote--large .vote-count")).toHaveText("0");

  // Comment
  await page.getByLabel("Add a comment").fill("Week view would be nice too.");
  await page.getByRole("button", { name: "Post comment" }).click();
  await expect(page.locator(".toast").last()).toContainText("Comment posted.");
  const comment = page.locator(".comment", { hasText: "Week view would be nice too." });
  await expect(comment).toContainText("Author");
  await expect(comment).toContainText("You");
  await expect(page.locator("#comments-title .count-pill")).toHaveText("1");

  // Edit comment inline
  await comment.getByRole("link", { name: "Edit" }).click();
  await page.getByLabel("Edit comment").fill("Week and month views would be nice.");
  await page.getByRole("button", { name: "Save" }).click();
  const edited = page.locator(".comment", { hasText: "Week and month views would be nice." });
  await expect(edited).toContainText("Edited");

  // Delete comment with confirmation
  await edited.getByRole("button", { name: "Delete" }).click();
  await confirmDialog(page, "Delete comment");
  await expect(page.locator(".comment")).toHaveCount(0);
  await expect(page.locator("#comments-title .count-pill")).toHaveText("0");

  // Edit suggestion
  await page.getByRole("link", { name: "Edit" }).click();
  await page.getByLabel("Title").fill(`${title} (edited)`);
  await page.getByRole("button", { name: "Save changes" }).click();
  await expect(page.locator(".toast")).toContainText("Changes saved.");
  await expect(page.locator(".byline-date")).toContainText("Edited");

  // Delete suggestion: cancel first, then confirm
  await page.locator(".owner-actions").getByRole("button", { name: "Delete" }).click();
  await page.locator("#confirm-dialog").getByRole("button", { name: "Cancel" }).click();
  await expect(page.getByRole("heading", { level: 1 })).toHaveText(`${title} (edited)`);
  await page.locator(".owner-actions").getByRole("button", { name: "Delete" }).click();
  await confirmDialog(page, "Delete suggestion");
  await expect(page.locator(".toast")).toContainText("Suggestion deleted.");
  await expect(page.getByRole("link", { name: `${title} (edited)` })).toHaveCount(0);

  await signOut(page);
});
