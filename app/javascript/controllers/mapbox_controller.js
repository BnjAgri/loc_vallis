import { Controller } from "@hotwired/stimulus"
import mapboxgl from "mapbox-gl"

export default class extends Controller {
  static values = {
    accessToken: String,
    lat: Number,
    lng: Number,
    zoom: { type: Number, default: 12 },
    interactive: { type: Boolean, default: false },
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
      style: "mapbox://styles/mapbox/streets-v12",
      center: [this.lngValue, this.latValue],
      zoom: initialZoom,
      interactive: this.interactiveValue,
      attributionControl: true
    })

    new mapboxgl.Marker().setLngLat([this.lngValue, this.latValue]).addTo(this.map)

    if (this.animateZoomValue) {
      this.map.once("load", () => {
        this.map.easeTo({
          zoom: targetZoom,
          duration: this.animateDurationMsValue
        })
      })
    }

    if (!this.interactiveValue) {
      this.map.scrollZoom.disable()
      this.map.boxZoom.disable()
      this.map.dragRotate.disable()
      this.map.dragPan.disable()
      this.map.keyboard.disable()
      this.map.doubleClickZoom.disable()
      this.map.touchZoomRotate.disable()
    }
  }

  disconnect() {
    if (this.map) this.map.remove()
  }
}
