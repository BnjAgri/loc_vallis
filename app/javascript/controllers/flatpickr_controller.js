import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
import "flatpickr/dist/l10n/fr.js"

export default class extends Controller {
  connect() {
    flatpickr(this.element, {
      allowInput: true,
      dateFormat: "Y-m-d",
      altInput: true,
      altFormat: "d/m/Y",
      altInputClass: "form-control",
      locale: "fr",
      disableMobile: true
    })
  }
}
