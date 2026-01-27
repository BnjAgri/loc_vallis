import { Controller } from "@hotwired/stimulus"
import mapboxgl from "mapbox-gl"

export default class extends Controller {
  static values = {
    accessToken: String,
    address: String,
    style: { type: String, default: "mapbox://styles/mapbox/streets-v12" },
    lat: Number,
    lng: Number,
    zoom: { type: Number, default: 12 },
    interactive: { type: Boolean, default: false },
    requireAlt: { type: Boolean, default: false },
    animateZoom: { type: Boolean, default: false },
    animateDurationMs: { type: Number, default: 2000 }
  }

  connect() {
    if (!this.hasAccessTokenValue || !this.accessTokenValue) return
    if (!this.hasLatValue || !this.hasLngValue) return

    mapboxgl.accessToken = this.accessTokenValue

    const targetZoom = this.zoomValue
    const initialZoom = this.animateZoomValue ? Math.max(1, targetZoom - 2) : targetZoom

    this.map = new mapboxgl.Map({
      container: this.element,
      style: this.styleValue,
      center: [this.lngValue, this.latValue],
      zoom: initialZoom,
      interactive: true,
      attributionControl: true
    })

    this.map.addControl(
      new mapboxgl.NavigationControl({ showCompass: false, showZoom: true }),
      "top-right"
    )

    this.marker = new mapboxgl.Marker().setLngLat([this.lngValue, this.latValue]).addTo(this.map)

    if (this.animateZoomValue) {
      this.map.once("load", () => {
        this.map.easeTo({
          zoom: targetZoom,
          duration: this.animateDurationMsValue
        })
      })
    }

    if (!this.interactiveValue) {
      this.disableInteractions()
    } else if (this.requireAltValue && !this.isTouchDevice()) {
      this.disableInteractions()
      this.installAltToInteractHandlers()
    }

    if (this.hasAddressValue && this.addressValue && this.addressValue.trim().length > 0) {
      this.geocodeAndRecenter(this.addressValue.trim())
    }
  }

  disableInteractions() {
    if (!this.map) return
    this.map.scrollZoom.disable()
    this.map.boxZoom.disable()
    this.map.dragRotate.disable()
    this.map.dragPan.disable()
    this.map.keyboard.disable()
    this.map.doubleClickZoom.disable()
    this.map.touchZoomRotate.disable()
  }

  enableInteractions() {
    if (!this.map) return
    this.map.scrollZoom.enable()
    this.map.boxZoom.enable()
    this.map.dragRotate.enable()
    this.map.dragPan.enable()
    this.map.keyboard.enable()
    this.map.doubleClickZoom.enable()
    this.map.touchZoomRotate.enable()
  }

  installAltToInteractHandlers() {
    this._altKeyDownHandler = (event) => {
      if (event.key === "Alt") this.enableInteractions()
    }

    this._altKeyUpHandler = (event) => {
      if (event.key === "Alt") this.disableInteractions()
    }

    window.addEventListener("keydown", this._altKeyDownHandler)
    window.addEventListener("keyup", this._altKeyUpHandler)

    this._windowBlurHandler = () => this.disableInteractions()
    window.addEventListener("blur", this._windowBlurHandler)
  }

  async geocodeAndRecenter(address) {
    if (!this.accessTokenValue) return

    const url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(address)}.json?access_token=${encodeURIComponent(this.accessTokenValue)}&limit=1`

    try {
      const response = await fetch(url, { headers: { Accept: "application/json" } })
      if (!response.ok) return

      const data = await response.json()
      const feature = Array.isArray(data?.features) ? data.features[0] : null
      const center = Array.isArray(feature?.center) ? feature.center : null
      if (!center || center.length < 2) return

      const [lng, lat] = center

      if (this.marker) this.marker.setLngLat([lng, lat])

      if (this.map.loaded()) {
        this.map.easeTo({ center: [lng, lat] })
      } else {
        this.map.once("load", () => {
          this.map.easeTo({ center: [lng, lat] })
        })
      }
    } catch (_error) {
      // Best-effort: keep fallback lat/lng.
    }
  }

  isTouchDevice() {
    return (navigator?.maxTouchPoints || 0) > 0
  }

  disconnect() {
    if (this._altKeyDownHandler) window.removeEventListener("keydown", this._altKeyDownHandler)
    if (this._altKeyUpHandler) window.removeEventListener("keyup", this._altKeyUpHandler)
    if (this._windowBlurHandler) window.removeEventListener("blur", this._windowBlurHandler)
    if (this.map) this.map.remove()
  }
}
