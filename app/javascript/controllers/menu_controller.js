import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu"]

  toggle() {
    const open = this.buttonTarget.getAttribute("aria-expanded") === "true"
    open ? this.close() : this.open()
  }

  open() {
    this.buttonTarget.setAttribute("aria-expanded", "true")
    this.menuTarget.hidden = false
    const first = this.menuTarget.querySelector(".menu-item")
    if (first) first.focus()
  }

  close() {
    if (this.buttonTarget.getAttribute("aria-expanded") !== "true") return
    this.buttonTarget.setAttribute("aria-expanded", "false")
    this.menuTarget.hidden = true
  }

  outside(event) {
    if (!this.element.contains(event.target)) this.close()
  }
}
