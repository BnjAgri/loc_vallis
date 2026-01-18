import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template", "item", "addLink"]
  static values = { max: Number }

  connect() {
    this.toggleAddLink()
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
