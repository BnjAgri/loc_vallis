import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["email", "password", "submit", "emailUnknown"]

  static values = {
    emailCheckUrl: String,
    debounceMs: { type: Number, default: 250 }
  }

  connect() {
    this.emailExists = false
    this.checkInFlight = false
    this._debounceTimer = null
    this._abortController = null

    this.update()
    this.queueEmailCheck()
  }

  update() {
    if (!this.hasSubmitTarget) return

    const email = this.hasEmailTarget ? this.emailTarget.value.trim() : ""
    const password = this.hasPasswordTarget ? this.passwordTarget.value : ""

    const hasRequiredFields = email.length > 0 && password.length > 0
    const canSubmit = hasRequiredFields && this.emailExists && !this.checkInFlight

    this.submitTarget.disabled = !canSubmit

    if (this.hasEmailUnknownTarget) {
      const showUnknown = email.length > 0 && !this.checkInFlight && !this.emailExists
      this.emailUnknownTarget.classList.toggle("d-none", !showUnknown)
    }
  }

  onInput() {
    this.update()
    this.queueEmailCheck()
  }

  onSubmit(event) {
    this.update()
    if (this.submitTarget.disabled) event.preventDefault()
  }

  queueEmailCheck() {
    if (!this.hasEmailTarget) return
    if (!this.hasEmailCheckUrlValue || !this.emailCheckUrlValue) return

    if (this._debounceTimer) window.clearTimeout(this._debounceTimer)
    this._debounceTimer = window.setTimeout(() => {
      this.checkEmailExists()
    }, this.debounceMsValue)
  }

  async checkEmailExists() {
    const email = this.emailTarget.value.trim()

    if (email.length === 0) {
      this.emailExists = false
      this.checkInFlight = false
      this.update()
      return
    }

    if (this._abortController) this._abortController.abort()
    this._abortController = new AbortController()

    this.checkInFlight = true
    this.update()

    try {
      const url = new URL(this.emailCheckUrlValue, window.location.origin)
      url.searchParams.set("email", email)

      const response = await fetch(url.toString(), {
        method: "GET",
        headers: { Accept: "application/json" },
        credentials: "same-origin",
        signal: this._abortController.signal
      })

      if (!response.ok) return

      const data = await response.json()
      this.emailExists = Boolean(data?.exists)
    } catch (error) {
      if (error?.name === "AbortError") return
      // Best-effort: keep the button disabled on errors.
      this.emailExists = false
    } finally {
      this.checkInFlight = false
      this.update()
    }
  }

  disconnect() {
    if (this._debounceTimer) window.clearTimeout(this._debounceTimer)
    if (this._abortController) this._abortController.abort()
  }
}
