import { Controller } from "@hotwired/stimulus"

// Keeps a scrollable container pinned to the bottom.
// Useful for message threads when content is re-rendered.
// Usage:
//   <div data-controller="scroll-to-bottom"> ... </div>
export default class extends Controller {
  connect() {
    this.scroll()

    this.observer = new MutationObserver(() => {
      this.scroll()
    })

    this.observer.observe(this.element, {
      childList: true,
      subtree: true
    })
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
  }

  scroll() {
    // Wait one frame so layout is settled.
    requestAnimationFrame(() => {
      this.element.scrollTop = this.element.scrollHeight
    })
  }
}
