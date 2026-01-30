import { Controller } from "@hotwired/stimulus"
import Swal from "sweetalert2"

export default class extends Controller {
  static values = {
    maxCents: Number,
    servicesCents: Number,
    currency: String
  }

  confirm(event) {
    // Prevent double-confirm loops.
    if (this.element.dataset.lvConfirmed === "true") return

    event.preventDefault()

    const maxCents = Number.isFinite(this.maxCentsValue) ? this.maxCentsValue : 0
    const servicesCents = Number.isFinite(this.servicesCentsValue) ? this.servicesCentsValue : 0
    const currency = (this.currencyValue || "EUR").toString().toUpperCase()

    const nightsCents = Math.max(0, maxCents - servicesCents)
    const partialCents = Math.min(
      maxCents,
      Math.round(nightsCents * 0.7) + servicesCents
    )

    const fullLabel = `Remboursement intégral (${this.formatMoney(maxCents, currency)})`
    const partialLabel = `70% des nuits + 100% des services (${this.formatMoney(partialCents, currency)})`
    const customLabel = "Somme libre"

    const html = `
      <div class="text-start">
        <p class="mb-2">Êtes-vous sûr de vouloir rembourser cette réservation ?</p>

        <div class="form-check mb-2">
          <input class="form-check-input" type="radio" name="refund_option" id="refund_full" value="full" checked>
          <label class="form-check-label" for="refund_full">${this.escapeHtml(fullLabel)}</label>
        </div>

        <div class="form-check mb-2">
          <input class="form-check-input" type="radio" name="refund_option" id="refund_partial" value="partial">
          <label class="form-check-label" for="refund_partial">${this.escapeHtml(partialLabel)}</label>
        </div>

        <div class="form-check mb-2">
          <input class="form-check-input" type="radio" name="refund_option" id="refund_custom" value="custom">
          <label class="form-check-label" for="refund_custom">${this.escapeHtml(customLabel)}</label>
        </div>

        <div class="mt-2">
          <label for="refund_custom_amount" class="form-label mb-1">Montant personnalisé (${this.escapeHtml(currency)})</label>
          <input id="refund_custom_amount" class="form-control" inputmode="decimal" placeholder="Ex: 49,90" disabled>
          <div class="form-text">Max: ${this.escapeHtml(this.formatMoney(maxCents, currency))}</div>
        </div>
      </div>
    `

    Swal.fire({
      icon: "warning",
      title: "Rembourser",
      html,
      showCancelButton: true,
      confirmButtonText: "Confirmer",
      cancelButtonText: "Annuler",
      reverseButtons: true,
      focusCancel: true,
      didOpen: () => {
        const modal = Swal.getHtmlContainer()
        if (!modal) return

        const customRadio = modal.querySelector("#refund_custom")
        const customInput = modal.querySelector("#refund_custom_amount")

        const sync = () => {
          const isCustom = customRadio?.checked
          if (customInput) {
            customInput.disabled = !isCustom
            if (isCustom) customInput.focus()
          }
        }

        modal.addEventListener("change", (e) => {
          const target = e.target
          if (!(target instanceof HTMLInputElement)) return
          if (target.name !== "refund_option") return
          sync()
        })

        sync()
      },
      preConfirm: () => {
        const modal = Swal.getHtmlContainer()
        if (!modal) return null

        const selected = modal.querySelector("input[name='refund_option']:checked")
        const option = selected ? selected.value : "full"

        if (option === "full") {
          return { amountCents: null }
        }

        if (option === "partial") {
          if (!Number.isFinite(partialCents) || partialCents <= 0) {
            Swal.showValidationMessage("Montant invalide")
            return null
          }
          return { amountCents: partialCents }
        }

        const customInput = modal.querySelector("#refund_custom_amount")
        const raw = (customInput && customInput.value ? customInput.value : "").trim()
        const amountCents = this.parseMoneyToCents(raw)

        if (!Number.isFinite(amountCents) || amountCents <= 0) {
          Swal.showValidationMessage("Veuillez saisir un montant valide")
          return null
        }

        if (amountCents > maxCents) {
          Swal.showValidationMessage("Le montant dépasse le total de la réservation")
          return null
        }

        return { amountCents }
      }
    }).then((result) => {
      if (!result.isConfirmed) return

      const amountField = this.element.querySelector("input[name='amount_cents']")
      if (amountField) {
        const amountCents = result.value?.amountCents
        amountField.value = amountCents == null ? "" : String(amountCents)
      }

      this.element.dataset.lvConfirmed = "true"

      if (typeof this.element.requestSubmit === "function") {
        this.element.requestSubmit()
      } else {
        this.element.submit()
      }
    })
  }

  formatMoney(cents, currency) {
    const amount = (Number(cents) || 0) / 100
    try {
      return new Intl.NumberFormat("fr-FR", {
        style: "currency",
        currency,
        currencyDisplay: "symbol"
      }).format(amount)
    } catch {
      return `${amount.toFixed(2)} ${currency}`
    }
  }

  parseMoneyToCents(input) {
    if (!input) return NaN

    // Accept both comma and dot decimals.
    const normalized = input.replace(/\s/g, "").replace(",", ".")

    if (!/^\d+(\.\d{1,2})?$/.test(normalized)) return NaN

    const value = Number.parseFloat(normalized)
    if (!Number.isFinite(value)) return NaN

    return Math.round(value * 100)
  }

  escapeHtml(str) {
    return String(str)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll("\"", "&quot;")
      .replaceAll("'", "&#39;")
  }
}
