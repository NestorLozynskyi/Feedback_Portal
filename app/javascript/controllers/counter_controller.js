import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "output"]
  static values = { max: Number }

  connect() { this.update() }
  update() { this.outputTarget.textContent = `${this.inputTarget.value.length}/${this.maxValue}` }
}
