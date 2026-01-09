import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"

export default class extends Controller {
  connect() {
    flatpickr(this.element, {
      allowInput: true,
      dateFormat: "Y-m-d",
      disableMobile: true
    })
  }
}
