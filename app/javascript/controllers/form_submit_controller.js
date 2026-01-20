import { Controller } from "@hotwired/stimulus"

// Disables the submit button and shows a spinner to avoid double-submits.
// Usage:
//   <form data-controller="form-submit" data-action="submit->form-submit#lock">
//     <button data-form-submit-target="button">Envoyer</button>
//   </form>
export default class extends Controller {
  static targets = ["button"]

  lock() {
    if (!this.hasButtonTarget) return

    this.buttonTarget.disabled = true

    const original = this.buttonTarget.innerHTML
    this.buttonTarget.dataset.originalHtml = original

    this.buttonTarget.innerHTML =
      '<span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>' +
      original
  }

  unlock() {
    if (!this.hasButtonTarget) return

    this.buttonTarget.disabled = false
    if (this.buttonTarget.dataset.originalHtml) {
      this.buttonTarget.innerHTML = this.buttonTarget.dataset.originalHtml
      delete this.buttonTarget.dataset.originalHtml
    }
  }
}
