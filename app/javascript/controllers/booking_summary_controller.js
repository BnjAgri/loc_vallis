import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "nightly", "nights", "total"]

  static values = {
    nightlyPriceCents: Number,
    currency: String
  }

  connect() {
    this.hide()
  }

  update(event) {
    if (!this.hasNightlyPriceCentsValue || this.nightlyPriceCentsValue <= 0) {
      this.hide()
      return
    }

    const { startDate, endDate } = event.detail || {}
    if (!startDate || !endDate) {
      this.hide()
      return
    }

    const start = new Date(`${startDate}T00:00:00`)
    const end = new Date(`${endDate}T00:00:00`)
    const diffMs = end.getTime() - start.getTime()
    const nights = Math.floor(diffMs / 86400000)

    if (!Number.isFinite(nights) || nights <= 0) {
      this.hide()
      return
    }

    const nightly = this.nightlyPriceCentsValue / 100.0
    const total = nightly * nights

    const currency = (this.currencyValue || "EUR").toUpperCase()
    const formatter = new Intl.NumberFormat(undefined, {
      style: "currency",
      currency
    })

    this.nightlyTarget.textContent = formatter.format(nightly)
    this.nightsTarget.textContent = `${nights}`
    this.totalTarget.textContent = formatter.format(total)

    this.show()
  }

  show() {
    this.panelTarget.classList.remove("d-none")
  }

  hide() {
    this.panelTarget.classList.add("d-none")
  }
}
