import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["banner", "installButton", "iosInstructions"]
  static values = {
    appName: String,
    dismissForDays: { type: Number, default: 14 }
  }

  connect() {
    if (!this.#isMobileViewport()) return
    if (this.#dismissedRecently()) return

    this.#updateNavbarOffset()
    this.onResize = () => this.#updateNavbarOffset()
    window.addEventListener("resize", this.onResize, { passive: true })

    this.deferredPrompt = null
    this.beforeInstallPromptHandler = (event) => this.#onBeforeInstallPrompt(event)
    this.appInstalledHandler = () => this.#onAppInstalled()

    window.addEventListener("beforeinstallprompt", this.beforeInstallPromptHandler)
    window.addEventListener("appinstalled", this.appInstalledHandler)

    if (this.#shouldShowIOSInstallHelp()) {
      this.#showIOS()
    }
  }

  disconnect() {
    window.removeEventListener("beforeinstallprompt", this.beforeInstallPromptHandler)
    window.removeEventListener("appinstalled", this.appInstalledHandler)
    window.removeEventListener("resize", this.onResize)
  }

  async install(event) {
    event?.preventDefault()

    if (!this.deferredPrompt) return

    this.deferredPrompt.prompt()

    try {
      await this.deferredPrompt.userChoice
    } finally {
      this.deferredPrompt = null
      this.dismiss()
    }
  }

  dismiss(event) {
    event?.preventDefault()
    this.#rememberDismiss()
    this.#hide()
  }

  #onBeforeInstallPrompt(event) {
    if (this.#dismissedRecently()) return
    if (this.#isInStandaloneMode()) return

    // Prevent the default mini-infobar.
    event.preventDefault()

    this.deferredPrompt = event
    this.#showAndroid()
  }

  #onAppInstalled() {
    this.deferredPrompt = null
    this.#hide()
    this.#rememberDismiss()
  }

  #showAndroid() {
    this.#show()
    this.installButtonTarget.hidden = false
    this.iosInstructionsTarget.hidden = true
  }

  #showIOS() {
    this.#show()
    this.installButtonTarget.hidden = true
    this.iosInstructionsTarget.hidden = false
  }

  #show() {
    this.bannerTarget.classList.add("is-visible")
  }

  #hide() {
    this.bannerTarget.classList.remove("is-visible")
  }

  #updateNavbarOffset() {
    // Keep the banner right under the navbar (which is sticky-top).
    const navbar = document.querySelector("nav.navbar")
    const height = navbar?.getBoundingClientRect()?.height || 0
    document.documentElement.style.setProperty("--lv-navbar-offset", `${Math.ceil(height)}px`)
  }

  #shouldShowIOSInstallHelp() {
    return this.#isIOS() && !this.#isInStandaloneMode()
  }

  #isIOS() {
    const ua = navigator.userAgent || ""

    // iPadOS can masquerade as Mac; use touch points as a heuristic.
    const isIPhoneOrIPod = /iPhone|iPod/i.test(ua)
    const isIPad = /iPad/i.test(ua) || (/(Macintosh)/i.test(ua) && navigator.maxTouchPoints > 1)

    return isIPhoneOrIPod || isIPad
  }

  #isMobileViewport() {
    return !window.matchMedia?.("(min-width: 768px)")?.matches
  }

  #isInStandaloneMode() {
    return window.matchMedia?.("(display-mode: standalone)")?.matches || window.navigator.standalone === true
  }

  #dismissKey() {
    return "lv:pwa_install:dismissed_at"
  }

  #dismissedRecently() {
    try {
      const raw = localStorage.getItem(this.#dismissKey())
      if (!raw) return false

      const dismissedAt = new Date(raw)
      if (Number.isNaN(dismissedAt.getTime())) return false

      const ms = this.dismissForDaysValue * 24 * 60 * 60 * 1000
      return Date.now() - dismissedAt.getTime() < ms
    } catch {
      return false
    }
  }

  #rememberDismiss() {
    try {
      localStorage.setItem(this.#dismissKey(), new Date().toISOString())
    } catch {
      // Ignore (private mode, storage disabled, etc.)
    }
  }
}
