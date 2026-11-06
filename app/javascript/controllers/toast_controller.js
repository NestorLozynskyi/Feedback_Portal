import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timer = setTimeout(() => {
      this.element.classList.add("is-leaving")
      setTimeout(() => this.element.remove(), 200)
    }, 4000)
  }

  disconnect() { clearTimeout(this.timer) }
}
