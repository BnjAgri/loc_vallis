import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "lv_admin_rooms_calendar_visibility"

export default class extends Controller {
  static targets = ["combined", "perRoomCalendar", "combinedToggle", "perRoomToggle"]

  connect() {
    const state = this.loadState()

    if (typeof state.showCombined === "boolean") {
      this.setVisible(this.combinedTargets, state.showCombined)
      if (this.hasCombinedToggleTarget) this.combinedToggleTarget.checked = state.showCombined
    }

    if (typeof state.showPerRoom === "boolean") {
      this.setVisible(this.perRoomCalendarTargets, state.showPerRoom)
      if (this.hasPerRoomToggleTarget) this.perRoomToggleTarget.checked = state.showPerRoom
    }
  }

  toggleCombined(event) {
    const show = !!event.target.checked
    this.setVisible(this.combinedTargets, show)
    this.saveState({ showCombined: show })
  }

  togglePerRoom(event) {
    const show = !!event.target.checked
    this.setVisible(this.perRoomCalendarTargets, show)
    this.saveState({ showPerRoom: show })
  }

  setVisible(elements, visible) {
    elements.forEach((el) => el.classList.toggle("d-none", !visible))
  }

  loadState() {
    try {
      return JSON.parse(window.localStorage.getItem(STORAGE_KEY) || "{}")
    } catch (_e) {
      return {}
    }
  }

  saveState(patch) {
    const current = this.loadState()
    const next = { ...current, ...patch }
    try {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify(next))
    } catch (_e) {
      // ignore
    }
  }
}
