// Quote Display JavaScript Module
// Handles real-time premium updates when add-ons are toggled
// Manages snow/ski date visibility and calculations

(function () {
  "use strict";

  const QuoteDisplay = {
    config: null,

    // Initialize with configuration data from server (read from data attribute)
    init: function () {
      // Read configuration from data attribute on the container element
      const container = document.querySelector("[data-quote-display-config]");
      if (container) {
        try {
          const configData = JSON.parse(
            container.getAttribute("data-quote-display-config")
          );
          this.config = {
            premiumData: configData.premium_data || {},
            cruiseAddOn: configData.cruise_add_on || 0,
            skiPerDay: configData.ski_per_day || 0,
            travellerCount: configData.traveller_count || 1,
            coverIds: configData.cover_ids || [],
          };
        } catch (e) {
          console.error("Failed to parse quote display configuration:", e);
          return;
        }
      } else {
        console.warn("Quote display configuration not found");
        return;
      }

      this.setupEventListeners();

      // Initialize snow dates visibility if snow is already checked
      const snowCheckbox = document.getElementById("quote_snow");
      if (snowCheckbox && snowCheckbox.checked) {
        document.getElementById("snow-dates")?.classList.remove("hidden");
      }

      // Update premiums after a short delay to ensure DOM is ready
      setTimeout(() => this.updatePremiums(), 100);
    },

    // Set up all event listeners
    setupEventListeners: function () {
      // Cruise checkbox
      const cruiseCheckbox = document.getElementById("quote_cruise");
      if (cruiseCheckbox) {
        cruiseCheckbox.addEventListener("change", () => this.updatePremiums());
      }

      // Snow checkbox
      const snowCheckbox = document.getElementById("quote_snow");
      if (snowCheckbox) {
        snowCheckbox.addEventListener("change", () => this.toggleSnowDates());
      }

      // Snow date fields
      const snowStartDate = document.getElementById("snow_start_date");
      const snowEndDate = document.getElementById("snow_end_date");
      if (snowStartDate) {
        snowStartDate.addEventListener("change", () => this.updatePremiums());
      }
      if (snowEndDate) {
        snowEndDate.addEventListener("change", () => this.updatePremiums());
      }

      // Cover radio buttons
      const coverRadios = document.querySelectorAll(
        'input[name="quote[cover_id]"]'
      );
      coverRadios.forEach((radio) => {
        radio.addEventListener("change", () => this.updatePremiums());
      });

      // Email quote form
      const emailForm = document.getElementById("email-quote-form");
      if (emailForm) {
        emailForm.addEventListener("submit", (e) => this.handleEmailSubmit(e));
      }
    },

    // Toggle visibility of snow/ski date fields
    toggleSnowDates: function () {
      const checkbox = document.getElementById("quote_snow");
      const datesContainer = document.getElementById("snow-dates");
      if (!checkbox || !datesContainer) return;

      if (checkbox.checked) {
        datesContainer.classList.remove("hidden");
        this.updatePremiums();
      } else {
        datesContainer.classList.add("hidden");
        const snowStartDate = document.getElementById("snow_start_date");
        const snowEndDate = document.getElementById("snow_end_date");
        if (snowStartDate) snowStartDate.value = "";
        if (snowEndDate) snowEndDate.value = "";
        this.updatePremiums();
      }
    },

    // Calculate number of ski days from date range
    calculateSnowDays: function () {
      const start = document.getElementById("snow_start_date")?.value;
      const end = document.getElementById("snow_end_date")?.value;
      if (!start || !end) return 0;

      const days =
        Math.ceil((new Date(end) - new Date(start)) / (1000 * 60 * 60 * 24)) +
        1;
      return days > 0 ? days : 0;
    },

    // Update all premium displays based on selected add-ons
    updatePremiums: function () {
      if (!this.config) return;

      const cruiseChecked =
        document.getElementById("quote_cruise")?.checked || false;
      const snowChecked =
        document.getElementById("quote_snow")?.checked || false;
      const snowDays = this.calculateSnowDays();

      const cruiseAmount = cruiseChecked
        ? this.config.cruiseAddOn * this.config.travellerCount
        : 0;
      const snowAmount =
        snowChecked && snowDays > 0
          ? this.config.skiPerDay * snowDays * this.config.travellerCount
          : 0;

      this.config.coverIds.forEach((coverId) => {
        this.updateCoverPremium(
          coverId,
          cruiseChecked,
          snowChecked,
          cruiseAmount,
          snowAmount
        );
      });
    },

    // Update premium display for a single coverage level
    updateCoverPremium: function (
      coverId,
      cruiseChecked,
      snowChecked,
      cruiseAmount,
      snowAmount
    ) {
      // Ensure we access premium data with both string and number keys
      const premiumData =
        this.config.premiumData[coverId] ||
        this.config.premiumData[String(coverId)] ||
        this.config.premiumData[Number(coverId)] ||
        {};

      // Ensure base_premium is a number
      const base = parseFloat(premiumData.base_premium) || 0;

      // Calculate final premium by adding base + add-ons
      const final = base + parseFloat(cruiseAmount) + parseFloat(snowAmount);

      this.updateElement(`base-${coverId}`, this.formatCurrency(base));
      this.toggleAddOn("cruise-", coverId, cruiseChecked, cruiseAmount);
      this.toggleAddOn(
        "snow-",
        coverId,
        snowChecked && snowAmount > 0,
        snowAmount
      );
      this.updateElement(`final-${coverId}`, this.formatCurrency(final));
    },

    // Show/hide add-on display and update amount
    toggleAddOn: function (prefix, coverId, show, amount) {
      const label = document.getElementById(`${prefix}label-${coverId}`);
      const amountEl = document.getElementById(`${prefix}amount-${coverId}`);

      if (show) {
        label?.classList.remove("hidden");
        if (amountEl) {
          amountEl.classList.remove("hidden");
          amountEl.textContent = this.formatCurrency(amount);
        }
      } else {
        label?.classList.add("hidden");
        amountEl?.classList.add("hidden");
      }
    },

    // Update text content of an element
    updateElement: function (id, text) {
      const el = document.getElementById(id);
      if (el) el.textContent = text;
    },

    // Format number as currency
    formatCurrency: function (amount) {
      return new Intl.NumberFormat("en-US", {
        style: "currency",
        currency: "USD",
        minimumFractionDigits: 2,
      }).format(amount);
    },

    // Handle email quote form submission
    handleEmailSubmit: function (e) {
      e.preventDefault();

      const emailInput = document.getElementById("email-address");
      const emailAddress = emailInput?.value.trim();

      if (!emailAddress) {
        return;
      }

      // Update the sent email address in the message
      const sentEmailSpan = document.getElementById("sent-email-address");
      if (sentEmailSpan) {
        sentEmailSpan.textContent = emailAddress;
      }

      // Update premium amounts in the email message (use current calculated values)
      this.config.coverIds.forEach((coverId) => {
        const finalPremiumEl = document.getElementById(`final-${coverId}`);
        const emailPremiumEl = document.getElementById(
          `email-premium-${coverId}`
        );
        if (finalPremiumEl && emailPremiumEl) {
          emailPremiumEl.textContent = finalPremiumEl.textContent;
        }
      });

      // Show the email sent message
      const emailSentMessage = document.getElementById("email-sent-message");
      if (emailSentMessage) {
        emailSentMessage.classList.remove("hidden");
        // Scroll to the message
        emailSentMessage.scrollIntoView({
          behavior: "smooth",
          block: "nearest",
        });
      }

      // Reset the form
      if (emailInput) {
        emailInput.value = "";
      }
    },
  };

  // Expose to global scope
  window.QuoteDisplay = QuoteDisplay;
})();
