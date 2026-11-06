import { Controller } from "@hotwired/stimulus"

// Put on a <form>: asks for confirmation in the shared dialog before submitting.
export default class extends Controller {
  static values = { title: String, body: String, label: String }

  ask(event) {
    if (this.confirmed) { this.confirmed = false; return }
    event.preventDefault()
    event.stopImmediatePropagation()
    const opener = event.submitter || document.activeElement
    window.dispatchEvent(new CustomEvent("confirm-dialog:open", {
      detail: {
        title: this.titleValue, body: this.bodyValue, label: this.labelValue, opener,
        onConfirm: () => { this.confirmed = true; this.element.requestSubmit() }
      }
    }))
  }
}
