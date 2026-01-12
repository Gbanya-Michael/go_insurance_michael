# Travel Insurance Premium Calculator

A Ruby on Rails app for calculating travel insurance premiums with three coverage levels (Basic, Plus, Elite) and optional cruise/snow add-ons.

## Quick Start

```bash
# Install dependencies
cd starter_project
bundle install
yarn install

#Build CSS
rails tailwindcss:build

# Setup database
rails db:prepare
rails db:fixtures:load

# Start server
rails server
```

Visit `http://localhost:3000`

For CSS auto-recompilation during development, run `yarn watch:css` in a separate terminal (or use `bin/rails tailwindcss:watch` via Procfile.dev).

## Features

- **Multi-traveller support** with age-based pricing
- **Multiple destinations** (highest zone determines pricing)
- **Three coverage levels**: Basic, Plus, Elite
- **Optional add-ons**: Cruise (per traveller) and Snow/Ski (per day per traveller)
- **Real-time premium updates** via JavaScript

## Validation Rules

- Ages: 1-84 years (adults 21+, children under 16 need adult companion)
- Dates: No past dates, max 18 months advance booking, max 2 years trip duration
- Required: At least one traveller, one destination, trip type, and excess level

## Premium Calculation

**Base Premium** = Base × Excess × Age × Duration × Destination × Trip Type × Cover

**Final Premium** = Base Premium + Cruise Add-on + Snow Add-on

- Cruise: Fixed amount per traveller (from highest zone destination)
- Snow: Per-day rate × ski days × number of travellers

## Running Tests

```bash
# All tests
bundle exec rspec

# Specific suites
bundle exec rspec spec/models/        # Model tests
bundle exec rspec spec/services/      # Premium calculation tests
bundle exec rspec spec/controllers/   # Controller tests
bundle exec rspec spec/system/       # E2E tests (requires Chrome/Firefox)
```

**Test Coverage**: 239 examples
Comprehensive coverage of premium calculation logic, validations, and user flows.
JavaScript is tested via system/E2E tests.

## Docker

```bash
# Build
cd starter_project
docker build -t travel-insurance .

# Run (development mode)
docker run -d -p 3000:80 \
  -e RAILS_ENV=development \
  -e SECRET_KEY_BASE=$(rails secret) \
  --name travel-insurance \
  travel-insurance
```

The Dockerfile automatically installs Node.js, builds Tailwind CSS, and sets up the database.

## Tech Stack

- **Backend**: Ruby 3.3.9, Rails 8.1.1, SQLite3
- **Frontend**: Tailwind CSS v4, vanilla JavaScript
- **Testing**: RSpec, Capybara, Selenium
- **Styling**: Tailwind CSS with custom primary color (#01A0C4)

## Project Structure

- `app/services/premium_calculator.rb` - Core calculation logic
- `app/models/quote.rb` - Quote model with validations
- `app/javascript/quote_form.js` - Form interactions
- `app/javascript/quote_display.js` - Real-time premium updates
- `spec/` - Comprehensive test suite

## Troubleshooting

**Database issues**: `rails db:reset && rails db:fixtures:load`

**Tests failing**: Ensure test DB is set up - `rails db:test:prepare`

**Port in use**: `lsof -i :3000` or use `rails server -p 3001`

**CSS not updating**:

- Development: Run `yarn watch:css` (auto-compiles on save) or `bin/rails tailwindcss:watch`
- One-time build: Run `yarn build:css` or `bin/rails tailwindcss:build`
- Note: Both approaches work; npm scripts for dev convenience, Rails commands for CI/production consistency
