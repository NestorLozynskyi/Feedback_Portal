import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "button"]

  toggle() {
    const show = this.inputTarget.type === "password"
    this.inputTarget.type = show ? "text" : "password"
    this.buttonTarget.textContent = show ? "Hide" : "Show"
    this.buttonTarget.setAttribute("aria-pressed", String(show))
    this.buttonTarget.setAttribute("aria-label", show ? "Hide password" : "Show password")
  }
}
