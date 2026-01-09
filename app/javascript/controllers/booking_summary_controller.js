import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "nightly", "nights", "total", "cta"]

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

    this.updateCtas(startDate, endDate)

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

  updateCtas(startDate, endDate) {
    if (!this.hasCtaTarget) return

    this.ctaTargets.forEach((link) => {
      const href = link.getAttribute("href")
      if (!href) return

      const url = new URL(href, window.location.origin)

      // If this CTA points to /login, we want to enrich its return_to.
      if (url.pathname === "/login") {
        const returnTo = url.searchParams.get("return_to")
        if (!returnTo) return

        const returnUrl = new URL(returnTo, window.location.origin)
        returnUrl.searchParams.set("start_date", startDate)
        returnUrl.searchParams.set("end_date", endDate)

        url.searchParams.set("return_to", `${returnUrl.pathname}${returnUrl.search}`)
        link.setAttribute("href", `${url.pathname}${url.search}`)
        return
      }

      // Otherwise, assume the CTA is the booking form and add dates directly.
      url.searchParams.set("start_date", startDate)
      url.searchParams.set("end_date", endDate)
      link.setAttribute("href", `${url.pathname}${url.search}`)
    })
  }

  show() {
    this.panelTarget.classList.remove("d-none")
  }

  hide() {
    this.panelTarget.classList.add("d-none")
  }
}
