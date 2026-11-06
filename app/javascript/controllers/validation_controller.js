import { Controller } from "@hotwired/stimulus"

// Client-side validation mirroring the mockups: runs on blur/change, clears while fixing,
// full check with an error summary on submit. The server validates the same rules.
// Each input has data-rules = {"required": msg, "minlength": [n, msg], "email": msg, "match": [id, msg]}.
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/

export default class extends Controller {
  static targets = ["input", "summary"]

  connect() {
    this.invalid = {}
    this.inputTargets.forEach((inp) => {
      const choice = inp.type === "radio" || inp.tagName === "SELECT"
      inp.addEventListener("blur", () => { if (!choice && (inp.value !== "" || this.invalid[this.key(inp)])) this.run(inp) })
      inp.addEventListener("change", () => { if (choice) this.run(inp) })
      inp.addEventListener("input", () => { if (this.invalid[this.key(inp)] && !this.check(inp)) this.run(inp) })
    })
  }

  submit(event) {
    const errors = this.validateAll()
    if (errors.length) {
      event.preventDefault()
      event.stopImmediatePropagation()
      this.renderSummary(errors)
    }
  }

  focusField(event) {
    event.preventDefault()
    const el = document.getElementById(event.currentTarget.dataset.field)
    if (el) el.focus()
  }

  key(inp) { return inp.type === "radio" ? inp.name : inp.id }

  rulesFor(inp) {
    if (inp.type === "radio") {
      const first = this.inputTargets.find((i) => i.name === inp.name && i.dataset.rules)
      return first ? JSON.parse(first.dataset.rules) : {}
    }
    return inp.dataset.rules ? JSON.parse(inp.dataset.rules) : {}
  }

  check(inp) {
    const r = this.rulesFor(inp)
    if (inp.type === "radio") {
      const any = this.inputTargets.some((i) => i.name === inp.name && i.checked)
      return !any && r.required ? r.required : ""
    }
    const raw = inp.value || ""
    const v = inp.type === "password" ? raw : raw.trim()
    if (!v) return r.required || ""
    if (r.email && !EMAIL_RE.test(v)) return r.email
    if (r.minlength && v.length < r.minlength[0]) return r.minlength[1]
    if (r.maxlength && v.length > r.maxlength[0]) return r.maxlength[1]
    if (r.match) {
      const other = document.getElementById(r.match[0])
      if (other && other.value !== raw) return r.match[1]
    }
    return ""
  }

  run(inp) {
    const msg = this.check(inp)
    const k = this.key(inp)
    this.invalid[k] = !!msg
    const errId = inp.type === "radio" ? `${inp.name.replace(/\W+/g, "-").replace(/-$/, "")}-error` : `${inp.id}-error`
    const errEl = document.getElementById(inp.dataset.errorId || errId)
    if (errEl) {
      errEl.innerHTML = msg ? `${this.alertIcon}<span></span>` : ""
      if (msg) errEl.querySelector("span").textContent = msg
      errEl.hidden = !msg
      const field = errEl.closest(".field")
      if (field) field.classList.toggle("is-invalid", !!msg)
    }
    const group = inp.type === "radio" ? this.inputTargets.filter((i) => i.name === inp.name) : [inp]
    group.forEach((i) => i.setAttribute("aria-invalid", msg ? "true" : "false"))
    return msg
  }

  validateAll() {
    const seen = new Set()
    const errors = []
    this.inputTargets.forEach((inp) => {
      const k = this.key(inp)
      if (seen.has(k)) return
      seen.add(k)
      const msg = this.run(inp)
      if (msg) errors.push({ focus: inp.id, msg })
    })
    return errors
  }

  renderSummary(errors) {
    if (!this.hasSummaryTarget) return
    const title = errors.length === 1 ? "There’s 1 problem to fix" : `There are ${errors.length} problems to fix`
    const box = document.createElement("div")
    box.className = "error-summary"
    box.setAttribute("role", "alert")
    box.tabIndex = -1
    const h = document.createElement("h2")
    h.className = "error-summary-title"
    h.textContent = title
    const ul = document.createElement("ul")
    errors.forEach((e) => {
      const li = document.createElement("li")
      const a = document.createElement("a")
      a.href = `#${e.focus}`
      a.dataset.field = e.focus
      a.dataset.action = "validation#focusField"
      a.textContent = e.msg
      li.appendChild(a)
      ul.appendChild(li)
    })
    box.append(h, ul)
    this.summaryTarget.replaceChildren(box)
    box.focus()
  }

  get alertIcon() {
    return '<svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><circle cx="12" cy="12" r="10"/><path d="M12 8v4M12 16h.01"/></svg>'
  }
}
