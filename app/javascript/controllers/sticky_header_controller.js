import { Controller } from "@hotwired/stimulus"

// Adds a subtle shadow to the navbar when scrolling.
// Usage:
//   <nav data-controller="sticky-header"> ... </nav>
export default class extends Controller {
  connect() {
    this.onScroll = this.onScroll.bind(this)
    window.addEventListener("scroll", this.onScroll, { passive: true })
    this.onScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
  }

  onScroll() {
    const elevated = window.scrollY > 8
    this.element.classList.toggle("lv-navbar--elevated", elevated)
  }
}
