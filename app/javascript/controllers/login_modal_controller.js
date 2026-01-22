import { Controller } from "@hotwired/stimulus"
import Swal from "sweetalert2"

export default class extends Controller {
  static targets = ["content"]

  connect() {
    this.open()
  }

  open() {
    if (!this.hasContentTarget) return

    const clone = this.contentTarget.cloneNode(true)

    Swal.fire({
      html: clone,
      showConfirmButton: false,
      showCloseButton: true,
      focusConfirm: false,
      didOpen: () => {
        // Prefer focusing the first input (email) if present.
        const firstInput = document.querySelector(".swal2-container input")
        if (firstInput) firstInput.focus()
      },
      didClose: () => {
        const destination = this.fallbackDestination()
        window.location.assign(destination)
      }
    })

    // Hide the inline content while the popup is visible.
    this.contentTarget.classList.add("d-none")
  }

  fallbackDestination() {
    const returnTo = this.safeRelativePath(new URLSearchParams(window.location.search).get("return_to"))
    if (returnTo) return returnTo

    const referrer = this.safeSameOriginPath(document.referrer)
    if (referrer) return referrer

    return "/"
  }

  safeRelativePath(value) {
    const path = (value || "").toString().trim()
    if (!path) return null
    if (!path.startsWith("/")) return null
    if (path.startsWith("//")) return null
    if (path.startsWith("/login")) return null
    return path
  }

  safeSameOriginPath(url) {
    const raw = (url || "").toString().trim()
    if (!raw) return null

    try {
      const uri = new URL(raw)
      if (uri.origin !== window.location.origin) return null

      const fullPath = `${uri.pathname}${uri.search}`
      return this.safeRelativePath(fullPath)
    } catch {
      return null
    }
  }
}
