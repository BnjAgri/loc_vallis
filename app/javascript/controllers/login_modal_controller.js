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
        // If the user closes the popup, show the normal page content as fallback.
        this.contentTarget.classList.remove("d-none")
      }
    })

    // Hide the inline content while the popup is visible.
    this.contentTarget.classList.add("d-none")
  }
}
