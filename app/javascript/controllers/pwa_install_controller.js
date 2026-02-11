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
    this.iosEligible = false
    this.userEngaged = false

    this.engagementTimeoutId = window.setTimeout(() => this.#markUserEngaged(), 30_000)
    this.onScroll = () => {
      // Consider the user engaged after a meaningful scroll.
      if ((window.scrollY || 0) >= 80) this.#markUserEngaged()
    }
    this.onPointerDown = () => this.#markUserEngaged()
    this.onKeyDown = (event) => {
      // Ignore modifier-only keys.
      const ignored = ["Shift", "Control", "Alt", "Meta"]
      if (ignored.includes(event?.key)) return
      this.#markUserEngaged()
    }

    window.addEventListener("scroll", this.onScroll, { passive: true })
    window.addEventListener("pointerdown", this.onPointerDown, { passive: true })
    window.addEventListener("keydown", this.onKeyDown)

    this.beforeInstallPromptHandler = (event) => this.#onBeforeInstallPrompt(event)
    this.appInstalledHandler = () => this.#onAppInstalled()

    window.addEventListener("beforeinstallprompt", this.beforeInstallPromptHandler)
    window.addEventListener("appinstalled", this.appInstalledHandler)

    if (this.#shouldShowIOSInstallHelp()) {
      this.iosEligible = true
      this.#maybeShowInstallPrompt()
    }
  }

  disconnect() {
    window.removeEventListener("beforeinstallprompt", this.beforeInstallPromptHandler)
    window.removeEventListener("appinstalled", this.appInstalledHandler)
    window.removeEventListener("resize", this.onResize)
    window.removeEventListener("scroll", this.onScroll)
    window.removeEventListener("pointerdown", this.onPointerDown)
    window.removeEventListener("keydown", this.onKeyDown)

    if (this.engagementTimeoutId) {
      window.clearTimeout(this.engagementTimeoutId)
      this.engagementTimeoutId = null
    }
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
    this.#maybeShowInstallPrompt()
  }

  #onAppInstalled() {
    this.deferredPrompt = null
    this.#hide()
    this.#rememberDismiss()
  }

  #markUserEngaged() {
    if (this.userEngaged) return
    this.userEngaged = true
    this.#maybeShowInstallPrompt()

    // We only need these until the first interaction.
    window.removeEventListener("scroll", this.onScroll)
    window.removeEventListener("pointerdown", this.onPointerDown)
    window.removeEventListener("keydown", this.onKeyDown)

    if (this.engagementTimeoutId) {
      window.clearTimeout(this.engagementTimeoutId)
      this.engagementTimeoutId = null
    }
  }

  #maybeShowInstallPrompt() {
    if (!this.userEngaged) return
    if (this.#dismissedRecently()) return
    if (this.#isInStandaloneMode()) return

    // Android/Chrome: show only if the browser has given us a deferred prompt.
    if (this.deferredPrompt) {
      this.#showAndroid()
      return
    }

    // iOS/Safari: show help banner once engaged.
    if (this.iosEligible) {
      this.#showIOS()
    }
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
