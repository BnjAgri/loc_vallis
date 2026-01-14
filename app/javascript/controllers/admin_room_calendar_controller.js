import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
import "flatpickr/dist/l10n/fr.js"

export default class extends Controller {
  static values = {
    openRanges: Array,
    bookedRanges: Array,
    pendingRanges: Array
  }

  connect() {
    this.openRanges = this.normalizeRanges(this.openRangesValue || [])
    this.bookedRanges = this.normalizeRanges(this.bookedRangesValue || [])
    this.pendingRanges = this.normalizeRanges(this.pendingRangesValue || [])

    const repaintHook = this.applyDayClasses.bind(this)
    const decorateHook = this.decorateDay.bind(this)

    this.picker = flatpickr(this.element, {
      inline: true,
      allowInput: false,
      clickOpens: false,
      dateFormat: "Y-m-d",
      locale: "fr",
      disableMobile: true,
      onChange: (_selectedDates, _dateStr, instance) => {
        instance.clear()
      },
      onDayCreate: [decorateHook],
      onReady: [repaintHook],
      onMonthChange: [repaintHook],
      onYearChange: [repaintHook],
      onValueUpdate: [repaintHook]
    })

    repaintHook([], "", this.picker)
  }

  disconnect() {
    if (this.picker) this.picker.destroy()
  }

  applyDayClasses(_selectedDates, _dateStr, instance) {
    const container = instance?.daysContainer
    if (!container) return

    container.querySelectorAll(".flatpickr-day").forEach((dayElem) => {
      this.decorateDayElement(dayElem)
    })
  }

  decorateDay(_selectedDates, _dateStr, dayElem) {
    this.decorateDayElement(dayElem)
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
      dayElem.title = "Demande en attente"
      return
    }

    if (this.isInAnyRange(dateKey, this.openRanges)) {
      dayElem.classList.add("lv-open-day")
      dayElem.title = "Ouvert"
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

    const [year, month = "1", day = "1"] = value.split("-")
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
