import { Controller } from "@hotwired/stimulus"
import Swal from "sweetalert2"

export default class extends Controller {
  static values = {
    message: String,
    confirmText: { type: String, default: "Supprimer" },
    cancelText: { type: String, default: "Annuler" }
  }

  confirm(event) {
    // If we've already confirmed once, let the form submit normally.
    if (this.element.dataset.lvConfirmed === "true") return

    event.preventDefault()

    const message =
      this.messageValue ||
      "Attention, supprimer cet élément le détruira définitivement. Etes-vous sûr ?"

    Swal.fire({
      icon: "warning",
      text: message,
      showCancelButton: true,
      confirmButtonText: this.confirmTextValue,
      cancelButtonText: this.cancelTextValue,
      confirmButtonColor: "#dc3545",
      cancelButtonColor: "#6c757d",
      reverseButtons: true,
      focusCancel: true
    }).then((result) => {
      if (!result.isConfirmed) return

      this.element.dataset.lvConfirmed = "true"

      if (this.element.tagName === "FORM") {
        if (typeof this.element.requestSubmit === "function") {
          this.element.requestSubmit()
        } else {
          this.element.submit()
        }
      } else {
        // For links, trigger a click to let Rails UJS handle the data-method
        this.element.click()
      }
    })
  }
}
