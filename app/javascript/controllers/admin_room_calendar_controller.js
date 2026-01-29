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

    this.onDayClick = this.onDayClick.bind(this)

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
      onReady: [repaintHook, (_selectedDates, _dateStr, instance) => this.bindClickHandler(instance)],
      onMonthChange: [repaintHook],
      onYearChange: [repaintHook],
      onValueUpdate: [repaintHook]
    })

    repaintHook([], "", this.picker)
  }

  disconnect() {
    if (this.picker?.daysContainer && this.onDayClick) {
      this.picker.daysContainer.removeEventListener("click", this.onDayClick)
    }

    if (this.picker) this.picker.destroy()
  }

  bindClickHandler(instance) {
    if (!instance?.daysContainer) return
    instance.daysContainer.removeEventListener("click", this.onDayClick)
    instance.daysContainer.addEventListener("click", this.onDayClick)
  }

  onDayClick(event) {
    const dayElem = event.target?.closest?.(".flatpickr-day")
    if (!dayElem?.dateObj) return

    const dateKey = this.formatDateKey(dayElem.dateObj)
    if (!dateKey) return

    const isBooked = this.isInAnyRange(dateKey, this.bookedRanges)
    const isPending = !isBooked && this.isInAnyRange(dateKey, this.pendingRanges)
    if (!isBooked && !isPending) return

    const kind = isBooked ? "booked" : "pending"
    const bookingId = this.bookingIdForDate(dateKey, isBooked ? this.bookedRanges : this.pendingRanges)

    if (bookingId) {
      window.location.href = `/admin/bookings/${bookingId}`
      return
    }

    const url = `/admin/bookings?date=${encodeURIComponent(dateKey)}&kind=${encodeURIComponent(kind)}`
    window.location.href = url
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
        to: this.normalizeDateString(range.to),
        bookingId: range.booking_id || range.bookingId || null
      }))
  }

  bookingIdForDate(dateKey, ranges) {
    const ids = new Set()

    ranges.forEach((range) => {
      if (!range?.from || !range?.to) return
      if (!(range.from <= dateKey && dateKey <= range.to)) return
      if (range.bookingId) ids.add(range.bookingId)
    })

    if (ids.size !== 1) return null
    return Array.from(ids)[0]
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
