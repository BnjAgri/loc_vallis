import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
import "flatpickr/dist/l10n/fr.js"

export default class extends Controller {
  static values = {
    openRanges: Array,
    bookedRanges: Array,
    pendingRanges: Array,
    disableOpenRanges: Boolean
  }

  connect() {
    this.openRanges = this.normalizeRanges(this.openRangesValue || [])

    this.bookedRanges = this.normalizeRanges(this.bookedRangesValue || [])
    this.pendingRanges = this.normalizeRanges(this.pendingRangesValue || [])

    const shouldDisableOpen = this.disableOpenRangesValue !== undefined ? this.disableOpenRangesValue : true
    const disableRanges = shouldDisableOpen ? this.openRanges : []

    flatpickr(this.element, {
      allowInput: true,
      dateFormat: "Y-m-d",
      altInput: true,
      altFormat: "d/m/Y",
      altInputClass: "form-control",
      locale: "fr",
      disableMobile: true,
      minDate: this.element.getAttribute("min") || null,
      maxDate: this.element.getAttribute("max") || null,
      disable: disableRanges,
      onDayCreate: (_selectedDates, _dateStr, _instance, dayElem) => {
        this.decorateDayElement(dayElem)
      }
    })
  }

  decorateDayElement(dayElem) {
    const date = dayElem?.dateObj
    if (!date) return

    const dateKey = this.formatDateKey(date)

    dayElem.classList.remove("lv-open-day", "lv-pending-day", "lv-booked-day")
    dayElem.removeAttribute("title")

    if (this.isInAnyRange(dateKey, this.bookedRanges)) {
      dayElem.classList.add("lv-booked-day")
      dayElem.title = "Réservé"
      return
    }

    if (this.isInAnyRange(dateKey, this.pendingRanges)) {
      dayElem.classList.add("lv-pending-day")
      dayElem.title = "Demande (requested)"
      return
    }

    if (this.isInAnyRange(dateKey, this.openRanges)) {
      dayElem.classList.add("lv-open-day")
      const shouldDisableOpen = this.disableOpenRangesValue !== undefined ? this.disableOpenRangesValue : true
      dayElem.title = shouldDisableOpen ? "Déjà ouvert" : "Ouvert"
    }
  }

  normalizeRanges(ranges) {
    return ranges
      .filter((range) => range && range.from && range.to)
      .map((range) => ({
        from: this.normalizeDateString(range.from),
        to: this.normalizeDateString(range.to)
      }))
  }

  normalizeDateString(value) {
    if (!value) return null

    if (value instanceof Date) {
      return this.formatDateKey(value)
    }

    const stringValue = `${value}`
    const [year, month = "1", day = "1"] = stringValue.split("-")
    const yyyy = year.padStart(4, "0")
    const mm = month.padStart(2, "0")
    const dd = day.padStart(2, "0").slice(0, 2)
    return `${yyyy}-${mm}-${dd}`
  }

  formatDateKey(date) {
    const year = date.getFullYear()
    const month = `${date.getMonth() + 1}`.padStart(2, "0")
    const day = `${date.getDate()}`.padStart(2, "0")
    return `${year}-${month}-${day}`
  }

  isInAnyRange(dateKey, ranges) {
    if (!dateKey) return false
    return ranges.some((range) => {
      if (!range.from || !range.to) return false
      return range.from <= dateKey && dateKey <= range.to
    })
  }
}
