import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
import "flatpickr/dist/l10n/fr.js"

export default class extends Controller {
  static values = {
    openRanges: Array
  }

  connect() {
    this.openRanges = this.normalizeRanges(this.openRangesValue || [])

    flatpickr(this.element, {
      allowInput: true,
      dateFormat: "Y-m-d",
      altInput: true,
      altFormat: "d/m/Y",
      altInputClass: "form-control",
      locale: "fr",
      disableMobile: true,
      disable: this.openRanges,
      onDayCreate: (_selectedDates, _dateStr, _instance, dayElem) => {
        this.decorateDayElement(dayElem)
      }
    })
  }

  decorateDayElement(dayElem) {
    const date = dayElem?.dateObj
    if (!date) return

    const dateKey = this.formatDateKey(date)

    dayElem.classList.remove("lv-open-day")
    dayElem.removeAttribute("title")

    if (this.isInAnyRange(dateKey, this.openRanges)) {
      dayElem.classList.add("lv-open-day")
      dayElem.title = "Déjà ouvert"
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
