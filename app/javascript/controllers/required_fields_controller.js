import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["required", "submit"]

  connect() {
    this.update()
  }

  update() {
    const allFilled = this.requiredTargets.every((element) => {
      if (element.disabled) return true

      if (element.type === "checkbox" || element.type === "radio") {
        return element.checked
      }

      const value = element.value ?? ""
      return value.toString().trim().length > 0
    })

    this.submitTarget.disabled = !allFilled
  }
}
