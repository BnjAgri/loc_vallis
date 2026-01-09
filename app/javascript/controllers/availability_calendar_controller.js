import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"

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
