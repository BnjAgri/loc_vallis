import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
import "flatpickr/dist/l10n/fr.js"

export default class extends Controller {
  static values = {
    enabledRanges: Array,
    disabledRanges: Array
  }

  handleChange(selectedDates, _dateStr, instance) {
    const detail = { startDate: null, endDate: null }

    if (selectedDates.length >= 1) {
      detail.startDate = instance.formatDate(selectedDates[0], "Y-m-d")
    }

    if (selectedDates.length >= 2) {
      detail.endDate = instance.formatDate(selectedDates[1], "Y-m-d")
    }

    this.element.dispatchEvent(
      new CustomEvent("availability-calendar:range-selected", {
        detail,
        bubbles: true
      })
    )
  }

  connect() {
    const enabled = (this.enabledRangesValue || []).map((range) => ({
      from: range.from,
      to: range.to
    }))

    const disabled = (this.disabledRangesValue || []).map((range) => ({
      from: range.from,
      to: range.to
    }))

    this.picker = flatpickr(this.element, {
      mode: "range",
      inline: true,
      allowInput: false,
      clickOpens: false,
      dateFormat: "Y-m-d",
      altInput: true,
      altFormat: "d/m/Y",
      altInputClass: "form-control",
      locale: "fr",
      rangeSeparator: " au ",
      disableMobile: true,
      enable: enabled,
      disable: disabled,
      onChange: this.handleChange.bind(this)
    })
  }

  disconnect() {
    if (this.picker) this.picker.destroy()
  }
}
