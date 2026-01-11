# Pin npm packages by running ./bin/importmap

pin "application"
pin "quote_form", to: "quote_form.js"
pin "quote_display", to: "quote_display.js"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
