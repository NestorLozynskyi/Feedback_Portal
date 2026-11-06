import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["title", "body", "confirm"]

  connect() {
    this.openHandler = (e) => this.open(e.detail)
    window.addEventListener("confirm-dialog:open", this.openHandler)
  }

  disconnect() { window.removeEventListener("confirm-dialog:open", this.openHandler) }

  open({ title, body, label, opener, onConfirm }) {
    this.titleTarget.textContent = title
    this.bodyTarget.textContent = body
    this.confirmTarget.textContent = label
    this.element.returnValue = ""
    this.element.addEventListener("close", () => {
      if (this.element.returnValue === "confirm") onConfirm()
      else if (opener && opener.isConnected && opener.focus) opener.focus()
    }, { once: true })
    this.element.showModal()
  }

  backdrop(event) {
    if (event.target === this.element) this.element.close("cancel")
  }
}
