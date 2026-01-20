import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "container"]

  preview() {
    const file = this.inputTarget.files && this.inputTarget.files[0]
    if (!file) return

    const url = URL.createObjectURL(file)

    this.previewTarget.src = url

    if (this.hasContainerTarget) {
      this.containerTarget.classList.remove("d-none")
    }
  }
}
