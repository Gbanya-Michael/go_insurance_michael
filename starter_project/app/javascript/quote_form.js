// Quote Form JavaScript Module
// Handles dynamic form interactions:
// - Adding/removing traveller fields
// - Destination selection and display
// - Date validation (max 2 years duration)
// - Form submission validation

(function () {
  "use strict";

  const QuoteForm = {
    selectedDestinations: [],

    // Initialize all form functionality
    init: function () {
      this.setupDateValidation();
      this.setupDestinationSelect();
      this.setupTravellerButtons();
      this.updateRemoveButtons();
    },

    // Set up event listeners for traveller add/remove buttons
    setupTravellerButtons: function () {
      const addButton = document.querySelector('[data-action="add-traveller"]');
      if (addButton) {
        addButton.addEventListener("click", () => this.addTraveller());
      }

      // Use event delegation for remove buttons (including dynamically added ones)
      const container = document.getElementById("travellers-container");
      if (container) {
        container.addEventListener("click", (e) => {
          if (e.target.matches('[data-action="remove-traveller"]')) {
            this.removeTraveller(e.target);
          }
        });
      }

      // Set up form submission validation
      const form = document.getElementById("quote-form");
      if (form) {
        form.addEventListener("submit", (e) => {
          if (!this.validateDestinations()) {
            e.preventDefault();
          }
        });
      }
    },

    // Add a new traveller input field
    addTraveller: function () {
      const container = document.getElementById("travellers-container");
      if (!container) return;

      const field = document.createElement("div");
      field.className =
        "flex items-center bg-white p-3 rounded-md gap-3 border border-primary shrink-0";

      const input = document.createElement("input");
      input.type = "number";
      input.name = "quote[travellers][][age]";
      input.placeholder = "Age";
      input.min = "1";
      input.max = "84";
      input.required = true;
      input.className =
        "w-32 px-3 py-2 rounded-md border-0 shrink-0 focus:outline-2 focus:outline-primary focus:outline-offset-2";

      const removeButton = document.createElement("button");
      removeButton.type = "button";
      removeButton.setAttribute("data-action", "remove-traveller");
      removeButton.className =
        "px-3 py-1 pl-2 text-red-600 hover:text-red-800 shrink-0 whitespace-nowrap";
      removeButton.textContent = "Remove";

      field.appendChild(input);
      field.appendChild(removeButton);
      container.appendChild(field);
      this.updateRemoveButtons();
    },

    // Remove a traveller field (hide remove button if only one remains)
    removeTraveller: function (button) {
      const field = button.closest("#travellers-container > div");
      if (field) {
        field.remove();
        this.updateRemoveButtons();
      }
    },

    // Show/hide remove buttons based on number of traveller fields
    updateRemoveButtons: function () {
      const fields = document.querySelectorAll("#travellers-container > div");
      fields.forEach((field) => {
        const removeButton = field.querySelector(
          '[data-action="remove-traveller"]'
        );
        if (removeButton) {
          removeButton.classList.toggle("hidden", fields.length === 1);
        }
      });
    },

    // Validate that at least one destination is selected before form submission
    validateDestinations: function () {
      if (this.selectedDestinations.length === 0) {
        alert("Please select at least one destination.");
        return false;
      }
      return true;
    },

    // Add a destination to the selected list
    addDestination: function (destinationId, label, zone) {
      const exists = this.selectedDestinations.some(
        (d) => d.id === destinationId
      );
      if (!exists) {
        this.selectedDestinations.push({
          id: destinationId,
          label: label,
          zone: zone,
        });
        this.updateDestinationDisplay();
        this.updateDestinationInput();
      }
      const select = document.getElementById("destination-select");
      if (select) select.value = "";
    },

    // Remove a destination from the selected list
    removeDestination: function (destinationId) {
      this.selectedDestinations = this.selectedDestinations.filter(
        (d) => d.id !== destinationId
      );
      this.updateDestinationDisplay();
      this.updateDestinationInput();
    },

    // Update the visual display of selected destinations as tags
    updateDestinationDisplay: function () {
      const container = document.getElementById("selected-destinations");
      if (!container) return;

      container.innerHTML = "";

      this.selectedDestinations.forEach((dest) => {
        const tag = document.createElement("div");
        tag.className =
          "bg-primary rounded-full inline-flex items-center px-3 py-1.5 text-sm text-white";

        const span = document.createElement("span");
        span.className = "text-white";
        span.textContent = `${this.escapeHtml(dest.label)} (Zone ${dest.zone})`;

        const removeButton = document.createElement("button");
        removeButton.type = "button";
        removeButton.setAttribute("data-action", "remove-destination");
        removeButton.setAttribute("data-destination-id", dest.id);
        removeButton.className =
          "ml-2 hover:text-gray-200 font-bold cursor-pointer bg-transparent border-0 text-white text-lg leading-none";
        removeButton.textContent = "×";

        // Set up event listener for remove button
        removeButton.addEventListener("click", () => {
          this.removeDestination(dest.id);
        });

        tag.appendChild(span);
        tag.appendChild(removeButton);
        container.appendChild(tag);
      });
    },

    // Create hidden form inputs for selected destinations
    updateDestinationInput: function () {
      const existingInputs = document.querySelectorAll(
        'input[name="quote[destination_ids][]"]'
      );
      existingInputs.forEach((input) => input.remove());

      const parent = document.getElementById("selected-destinations");
      if (!parent) return;

      this.selectedDestinations.forEach((dest) => {
        const input = document.createElement("input");
        input.type = "hidden";
        input.name = "quote[destination_ids][]";
        input.value = dest.id;
        parent.parentNode.appendChild(input);
      });
    },

    // Set up date validation - end date must be within 2 years of start date
    setupDateValidation: function () {
      const startDateField = document.getElementById("quote_start_date");
      const endDateField = document.getElementById("quote_end_date");

      if (startDateField && endDateField) {
        startDateField.addEventListener("change", function () {
          const startDate = new Date(this.value);
          if (!isNaN(startDate.getTime())) {
            const maxDate = new Date(startDate);
            maxDate.setFullYear(maxDate.getFullYear() + 2);
            endDateField.min = this.value;
            endDateField.max = maxDate.toISOString().split("T")[0];
          }
        });
      }
    },

    // Set up destination dropdown to add selections to the list
    setupDestinationSelect: function () {
      const select = document.getElementById("destination-select");
      if (select) {
        select.addEventListener("change", function () {
          if (this.value) {
            const option = this.options[this.selectedIndex];
            const label = option.getAttribute("data-label");
            const zone = option.getAttribute("data-zone");
            if (label && zone) {
              QuoteForm.addDestination(this.value, label, zone);
            }
          }
        });
      }
    },

    // Escape HTML to prevent XSS attacks
    escapeHtml: function (text) {
      const div = document.createElement("div");
      div.textContent = text;
      return div.innerHTML;
    },
  };

  // Initialize when DOM is ready
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", () => QuoteForm.init());
  } else {
    QuoteForm.init();
  }

  // Expose to global scope for backwards compatibility (if needed)
  window.QuoteForm = QuoteForm;
})();
