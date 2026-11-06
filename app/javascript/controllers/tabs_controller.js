import { Controller } from "@hotwired/stimulus"

// Roadmap columns become tabs on mobile.
export default class extends Controller {
  static targets = ["tab", "panel"]

  select(event) { this.show(event.currentTarget.dataset.col, false) }

  keydown(event) {
    if (event.key !== "ArrowRight" && event.key !== "ArrowLeft") return
    event.preventDefault()
    const cols = this.tabTargets.map((t) => t.dataset.col)
    const i = cols.indexOf(event.currentTarget.dataset.col)
    const n = cols[(i + (event.key === "ArrowRight" ? 1 : -1) + cols.length) % cols.length]
    this.show(n, true)
  }

  show(col, focus) {
    this.tabTargets.forEach((t) => {
      const on = t.dataset.col === col
      t.setAttribute("aria-selected", String(on))
      t.tabIndex = on ? 0 : -1
      if (on && focus) t.focus()
    })
    this.panelTargets.forEach((p) => p.classList.toggle("is-active", p.dataset.status === col))
  }
}
