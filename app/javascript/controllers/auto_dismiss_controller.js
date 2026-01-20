import { Controller } from "@hotwired/stimulus"
import Alert from "bootstrap/js/dist/alert"

// Auto-dismiss alerts after a delay (progressive enhancement).
// Usage:
//   <div data-controller="auto-dismiss" data-auto-dismiss-delay-value="5000">...</div>
export default class extends Controller {
  static values = { delay: Number }

  connect() {
    const delay = this.hasDelayValue ? this.delayValue : 5000
    this.timeout = window.setTimeout(() => {
      this.dismiss()
    }, delay)
  }

  disconnect() {
    if (this.timeout) window.clearTimeout(this.timeout)
  }

  dismiss() {
    try {
      const alert = Alert.getOrCreateInstance(this.element)
      alert.close()
    } catch (e) {
      this.element.remove()
    }
  }
}
