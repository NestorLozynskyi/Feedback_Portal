import { Controller } from "@hotwired/stimulus"

// Light/dark theme on <html data-theme>. The choice is stored; without it the system setting applies (see layout head script).
export default class extends Controller {
  connect() { this.updateLabel() }

  toggle() {
    const next = this.current === "dark" ? "light" : "dark"
    document.documentElement.dataset.theme = next
    try { localStorage.setItem("fp-theme", next) } catch (e) { /* storage unavailable */ }
    this.updateLabel()
  }

  get current() { return document.documentElement.dataset.theme === "dark" ? "dark" : "light" }

  updateLabel() {
    this.element.setAttribute("aria-label", this.current === "dark" ? "Switch to light theme" : "Switch to dark theme")
  }
}
