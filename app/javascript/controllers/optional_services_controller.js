import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template", "item", "addLink"]
  static values = { max: Number }

  connect() {
    this.toggleAddLink()

    this.onSubmit = this.onSubmit.bind(this)

    const form = this.element.closest("form")
    if (form) form.addEventListener("submit", this.onSubmit)
  }

  disconnect() {
    const form = this.element.closest("form")
    if (form && this.onSubmit) form.removeEventListener("submit", this.onSubmit)
  }

  onSubmit(event) {
    // Clear any previous custom validity.
    this.itemTargets.forEach((row) => {
      const priceInput = row.querySelector("input[name$='[price_eur]']")
      if (priceInput) priceInput.setCustomValidity("")
    })

    for (const row of this.itemTargets) {
      const nameInput = row.querySelector("input[name$='[name]']")
      const priceInput = row.querySelector("input[name$='[price_eur]']")
      if (!nameInput || !priceInput) continue

      const name = nameInput.value?.trim?.() || ""
      const price = priceInput.value?.trim?.() || ""

      // Match server-side rule: if name is present, price is required.
      if (name.length > 0 && price.length === 0) {
        priceInput.setCustomValidity("Prix requis")
        priceInput.reportValidity()
        event.preventDefault()
        event.stopPropagation()
        priceInput.focus()
        return
      }
    }
  }

  add(event) {
    event.preventDefault()

    if (this.itemTargets.length >= this.maxValue) return

    const html = this.templateTarget.innerHTML

    this.listTarget.insertAdjacentHTML("beforeend", html)
    this.toggleAddLink()
  }

  remove(event) {
    event.preventDefault()

    const row = event.target.closest("[data-optional-services-target='item']")
    if (!row) return

    row.remove()
    this.toggleAddLink()
  }

  toggleAddLink() {
    if (!this.hasAddLinkTarget) return

    this.addLinkTarget.classList.toggle("d-none", this.itemTargets.length >= this.maxValue)
  }
}
