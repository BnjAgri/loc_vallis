import { Controller } from "@hotwired/stimulus"

// Persists the booking request form state (dates + optional services + terms)
// so users can open the CGV page and come back without losing selections.
export default class extends Controller {
  static values = {
    key: String,
  }

  connect() {
    this._onChange = this.persist.bind(this)
    this._onSubmit = this.clear.bind(this)
    this._onPageShow = this.restore.bind(this)

    this.element.addEventListener("change", this._onChange)
    this.element.addEventListener("input", this._onChange)
    this.element.addEventListener("submit", this._onSubmit)
    window.addEventListener("pageshow", this._onPageShow)

    this.restore()
  }

  disconnect() {
    this.element.removeEventListener("change", this._onChange)
    this.element.removeEventListener("input", this._onChange)
    this.element.removeEventListener("submit", this._onSubmit)
    window.removeEventListener("pageshow", this._onPageShow)
  }

  persist() {
    try {
      sessionStorage.setItem(this.storageKey(), JSON.stringify(this.currentState()))
    } catch (_e) {
      // Ignore storage failures (private mode, quota, etc.)
    }
  }

  restore() {
    const raw = sessionStorage.getItem(this.storageKey())
    if (!raw) return

    let data
    try {
      data = JSON.parse(raw)
    } catch (_e) {
      return
    }

    if (!data || typeof data !== "object") return

    const startInput = this.element.querySelector("#booking_start_date")
    const endInput = this.element.querySelector("#booking_end_date")
    const termsInput = this.element.querySelector("#booking_accepts_terms")

    if (startInput && typeof data.startDate === "string" && startInput.value === "") {
      startInput.value = data.startDate
    }

    if (endInput && typeof data.endDate === "string" && endInput.value === "") {
      endInput.value = data.endDate
    }

    if (termsInput && typeof data.acceptsTerms === "boolean") {
      termsInput.checked = data.acceptsTerms
      termsInput.dispatchEvent(new Event("change", { bubbles: true }))
    }

    if (Array.isArray(data.optionalServiceNames)) {
      const wanted = new Set(data.optionalServiceNames.map((n) => String(n)))
      this.element
        .querySelectorAll('input[name="booking[optional_service_names][]"]')
        .forEach((input) => {
          input.checked = wanted.has(String(input.value))
        })
    }
  }

  clear() {
    try {
      sessionStorage.removeItem(this.storageKey())
    } catch (_e) {
      // ignore
    }
  }

  storageKey() {
    const key = this.hasKeyValue && this.keyValue ? this.keyValue : window.location.pathname
    return `lv:booking_form:${key}`
  }

  currentState() {
    const startInput = this.element.querySelector("#booking_start_date")
    const endInput = this.element.querySelector("#booking_end_date")
    const termsInput = this.element.querySelector("#booking_accepts_terms")

    const optionalServiceNames = Array.from(
      this.element.querySelectorAll('input[name="booking[optional_service_names][]"]:checked')
    ).map((input) => input.value)

    return {
      startDate: startInput ? startInput.value : "",
      endDate: endInput ? endInput.value : "",
      acceptsTerms: termsInput ? Boolean(termsInput.checked) : false,
      optionalServiceNames,
    }
  }
}
