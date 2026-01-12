// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";

// Load flash message handler if flash message is present
if (document.getElementById("flash-message")) {
  import("flash_message");
}

// Conditionally load quote form JavaScript on quote form page
// Note: Quote form module auto-initializes when imported
if (
  document.querySelector("#quote-form") &&
  !document.querySelector("[data-quote-display-config]")
) {
  import("quote_form");
}

// Conditionally load quote display JavaScript on quote show page
// Note: Quote display requires manual initialization after config is loaded
if (document.querySelector("[data-quote-display-config]")) {
  import("quote_display").then(() => {
    // Initialize after module loads
    const initQuoteDisplay = () => {
      if (window.QuoteDisplay) {
        window.QuoteDisplay.init();
      } else {
        setTimeout(initQuoteDisplay, 50);
      }
    };

    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", initQuoteDisplay);
    } else {
      initQuoteDisplay();
    }
  });
}
