import { Controller } from "@hotwired/stimulus"

// Escape inside an inline edit form follows its Cancel link.
export default class extends Controller {
  static targets = ["cancel"]
  cancel(event) {
    if (event.key === "Escape" && this.hasCancelTarget) { event.preventDefault(); this.cancelTarget.click() }
  }
}
