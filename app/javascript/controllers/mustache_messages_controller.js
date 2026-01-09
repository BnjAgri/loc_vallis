import { Controller } from "@hotwired/stimulus"
import Mustache from "mustache"

export default class extends Controller {
  static targets = ["list", "template"]
  static values = {
    messages: Array
  }

  connect() {
    if (!this.hasListTarget || !this.hasTemplateTarget) return

    const view = { messages: this.messagesValue || [] }
    const html = Mustache.render(this.templateTarget.innerHTML.trim(), view)
    this.listTarget.innerHTML = html
  }
}
