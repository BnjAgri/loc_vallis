# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "bootstrap", to: "bootstrap.min.js", preload: true
pin "@popperjs/core", to: "popper.js", preload: true
pin "flatpickr" # @4.6.13
pin "mustache" # @4.2.0
pin "sweetalert2", to: "https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.esm.all.min.js", preload: true
pin "mapbox-gl", to: "https://esm.sh/mapbox-gl@2.15.0"
pin "flatpickr/dist/l10n/fr.js", to: "flatpickr--dist--l10n--fr.js.js" # @4.6.13
