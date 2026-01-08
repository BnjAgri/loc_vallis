import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"

export default class extends Controller {
  static values = {
    enabledRanges: Array,
    disabledRanges: Array
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
      inline: true,
      allowInput: false,
      clickOpens: false,
      dateFormat: "Y-m-d",
      disableMobile: true,
      enable: enabled,
      disable: disabled
    })
  }

  disconnect() {
    if (this.picker) this.picker.destroy()
  }
}
