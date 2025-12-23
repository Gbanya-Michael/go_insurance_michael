# Travel Insurance Premium Calculator

A Ruby on Rails application for calculating and displaying travel insurance premiums. The app supports three coverage levels (Basic, Plus, Elite) with optional add-ons for cruise and snow/ski coverage.

## Features

### User Input Form

The form collects all necessary travel details:

- **Travellers**: Supports multiple travellers with age input. Each traveller's age is used in premium calculation.
- **Trip Dates**: Start and end dates with validation to ensure reasonable booking windows.
- **Destinations**: Multiple destination selection with zone-based pricing. The highest zone determines the multiplier.
- **Trip Type**: One Way or Return trip selection.
- **Excess Level**: User-selectable excess options that affect premium pricing.

### Form Validation

Comprehensive validation ensures data quality and business rule compliance:

- **Age Rules**:
  - Minimum age: 1 year
  - Maximum age: 84 years
  - Adults are recognized as 21+ years old
  - Children under 16 must travel with at least one adult (21+)
- **Date Rules**:
  - Start date cannot be in the past
  - Start date cannot be more than 18 months in advance
  - End date must be after start date
  - Trip duration cannot exceed 2 years (730 days)
- **Required Fields**: All form fields are validated with clear error messages displayed to users.

### Premium Calculation

The premium calculation follows a structured formula:

**Base Premium Formula:**

```
Base Premium = Base × Excess × Age × Duration × Destination × Trip Type × Level of Cover
```

Each factor is looked up from the database:

- **Base**: Base premium multiplier from `premia` table
- **Excess**: Multiplier from selected excess level
- **Age**: Multiplier based on traveller's age range
- **Duration**: Multiplier based on trip duration in days
- **Destination**: Multiplier from the highest zone destination selected
- **Trip Type**: Multiplier for One Way (1.0) or Return (1.2)
- **Level of Cover**: Multiplier for Basic (1.0), Plus (1.45), or Elite (1.55)

**Final Premium Formula:**

```
Final Premium = Base Premium + Cruise Add-on + Snow Add-on
```

**Add-ons:**

- **Cruise**: Fixed amount per traveller based on the highest destination zone
- **Snow/Ski**: Per-day rate × number of ski days × number of travellers

The calculation handles multiple travellers by summing individual base premiums, then applying add-ons across all travellers.

### Premium Display

After form submission, users see:

- **Three Coverage Levels**: Basic, Plus, and Elite premiums displayed side-by-side
- **Selectable Add-ons**: Checkboxes for Cruise and Snow/Ski coverage
- **Real-time Updates**: JavaScript updates all prices instantly when add-ons are toggled or ski dates are changed
- **Coverage Selection**: Radio buttons to select the desired coverage level
- **Quote Summary**: Trip details displayed at the top for reference

## Prerequisites

Before getting started, ensure you have:

- Ruby 3.3.9 (or compatible version)
- Rails 8.1.1
- SQLite3
- Node.js and npm (for Tailwind CSS compilation)

## Setup Instructions

### Quick Start

1. **Install dependencies**:

   ```bash
   bundle install
   ```

2. **Set up the database**:

   ```bash
   rails db:prepare
   rails db:fixtures:load
   ```

   This creates all necessary tables and loads test data from fixtures located in `test/fixtures/`.

3. **Start the server**:

   ```bash
   rails server
   ```

4. **Access the application**:
   Open your browser and navigate to `http://localhost:3000`

The application will be ready to use. You can start creating quotes immediately with the test data loaded.

## Running Tests

The application includes a comprehensive test suite using RSpec. Tests cover models, services, controllers, and end-to-end user flows.

### Running All Tests

```bash
bundle exec rspec
```

### Running Specific Test Suites

**Model tests:**

```bash
bundle exec rspec spec/models/
```

**Service tests (premium calculation logic):**

```bash
bundle exec rspec spec/services/
```

**Controller tests:**

```bash
bundle exec rspec spec/controllers/
```

**System/Integration tests:**

```bash
bundle exec rspec spec/system/
```

### Test Coverage

The test suite includes:

- **Model tests**: Validations, associations, and data integrity
- **Service tests**: Premium calculation logic with various scenarios
- **Controller tests**: Request handling, validation, and redirects
- **System tests**: End-to-end user flows using Capybara

Note: System tests require a JavaScript driver. The application is configured to use Selenium WebDriver. Make sure you have Chrome or Firefox installed for browser-based tests.

## Application Structure

### Key Components

**Controllers** (`app/controllers/quotes_controller.rb`):

- Handles form submission and validation
- Manages quote creation and updates
- Validates business rules (age requirements, date constraints, etc.)
- Renders quote display with calculated premiums

**Services** (`app/services/premium_calculator.rb`):

- Core premium calculation logic
- Handles base premium calculation per traveller
- Calculates add-ons (cruise and snow/ski)
- Determines highest zone destination for pricing

**Models**:

- `app/models/quote.rb` - Main quote model with associations
- `app/models/destination.rb` - Destination data with zones and add-on pricing
- `app/models/cover.rb` - Coverage levels (Basic, Plus, Elite)
- `app/models/age.rb` - Age ranges with multipliers
- `app/models/duration.rb` - Trip duration ranges with multipliers
- `app/models/excess.rb` - Excess options with multipliers
- `app/models/trip_type.rb` - One Way or Return trip types
- `app/models/premium.rb` - Base premium configuration

**Views**:

- `app/views/quotes/new.html.erb` - Quote input form with validation
- `app/views/quotes/show.html.erb` - Premium display with real-time updates

### Database Schema

The application uses SQLite3 with the following main tables:

- `quotes` - Stores quote information including travellers, dates, and selected options
- `destinations` - Destination data with zones, multipliers, and add-on pricing
- `covers` - Coverage levels (Basic, Plus, Elite) with multipliers
- `ages` - Age ranges with corresponding multipliers
- `durations` - Trip duration ranges with multipliers
- `excesses` - Excess options with multipliers
- `trip_types` - One Way or Return trip types with multipliers
- `premia` - Base premium configuration
- `quotes_to_destinations` - Join table linking quotes to multiple destinations

Test data is provided in `test/fixtures/` and can be loaded with `rails db:fixtures:load`.

## Usage Guide

### Creating a Quote

1. **Navigate to the home page** - The form loads automatically at the root path
2. **Enter traveller information**:
   - Add one or more travellers with their ages
   - Remember: children under 16 must have an adult (21+) in the group
3. **Select trip dates**:
   - Start date must be today or in the future (up to 18 months ahead)
   - End date must be after start date
   - Maximum trip duration is 2 years
4. **Choose destinations**:
   - Select all destinations you'll be visiting
   - The highest zone will be used for pricing
5. **Select trip type and excess**:
   - Choose One Way or Return
   - Select your preferred excess level
6. **Submit the form** - Click "Get Quote" to see premium options

### Viewing and Customizing Premiums

After submission, you'll see:

1. **Three coverage options** (Basic, Plus, Elite) with base premiums
2. **Optional add-ons**:
   - **Cruise Coverage**: Check the box to add a fixed amount per traveller
   - **Snow/Ski Coverage**: Check the box and enter your ski date range
3. **Real-time price updates** - Prices update instantly as you toggle add-ons
4. **Select your coverage** - Choose Basic, Plus, or Elite using the radio buttons
5. **Save your quote** - Click "Update Quote" to save your selections

The quote is saved with a unique ID that you can reference later.

## Technical Details

### Premium Calculation Logic

The premium calculation is handled by the `PremiumCalculator` service class. Here's how it works:

**For each traveller:**

1. Look up age multiplier based on traveller's age
2. Look up duration multiplier based on trip length in days
3. Get destination multiplier from the highest zone destination
4. Get multipliers for excess, trip type, and cover level
5. Calculate: `Base × Excess × Age × Duration × Destination × Trip Type × Cover`

**Sum all travellers' base premiums**, then add optional add-ons:

- **Cruise Add-on**: `cruise_add_on_amount` (from highest zone destination) × number of travellers
- **Snow Add-on**: `ski_per_day_amount` (from highest zone destination) × number of ski days × number of travellers

**Final Premium** = Sum of all traveller base premiums + Cruise Add-on + Snow Add-on

### Validation Implementation

Validation is performed in the controller before saving. Key validations include:

- **Traveller validation**: Ensures at least one traveller, ages are within 1-84 range, and children under 16 have an adult companion
- **Date validation**: Prevents past dates, enforces 18-month advance booking limit, ensures end date is after start date, and limits trip duration to 2 years
- **Destination validation**: Requires at least one destination selection
- **Required fields**: All form fields are validated with user-friendly error messages

Errors are displayed at the top of the form with clear messaging to help users correct their input.

## Development Notes

### Code Organization

The codebase follows Rails conventions with clear separation of concerns:

- **Business logic** is isolated in service objects (`PremiumCalculator`)
- **Validation logic** is centralized in the controller for better user experience
- **View logic** uses minimal JavaScript for real-time updates
- **Database queries** are optimized with proper indexing

### Styling

The application uses Tailwind CSS for styling, providing a clean and responsive interface. The color scheme uses a teal accent color (#01A0C4) for primary actions and highlights which I beleive is the color for go insurance.

### JavaScript Functionality

Real-time premium updates are handled with vanilla JavaScript (no framework dependencies). The script:

- Watches for checkbox changes on add-ons
- Calculates add-on amounts client-side
- Updates all three coverage level prices instantly
- Handles date range calculations for snow/ski coverage

## Docker Support

The application includes a `Dockerfile` for containerization. The container automatically sets up the database and loads fixtures on startup.

### Prerequisites

- Docker installed and running
- Docker Desktop (for macOS/Windows) or Docker Engine (for Linux)

### Building the Docker Image

From the `starter_project` directory:

```bash
docker build -t travel-insurance .
```

This will:

- Build a multi-stage Docker image
- Install all dependencies
- Precompile assets
- Create an optimized production-ready image

**Note**: The build process may take several minutes on first run.

### Running the Container

#### Development Mode (Recommended for Testing)

For development and testing, run in development mode:

```bash
# Stop and remove existing container (if any)
docker stop travel-insurance 2>/dev/null
docker rm travel-insurance 2>/dev/null

# Run the container in development mode
docker run -d -p 3000:80 \
  -e RAILS_ENV=development \
  -e SECRET_KEY_BASE=$(rails secret) \
  --name travel-insurance \
  travel-insurance
```

#### Production Mode (If Master Key Available)

If you have `config/master.key` file:

```bash
# Stop and remove existing container (if any)
docker stop travel-insurance 2>/dev/null
docker rm travel-insurance 2>/dev/null

# Run the container in production mode
docker run -d -p 3000:80 \
  -e RAILS_MASTER_KEY=$(cat config/master.key) \
  -e SECRET_KEY_BASE=$(rails secret) \
  --name travel-insurance \
  travel-insurance
```

### Accessing the Application

Once the container is running:

1. **Check container status**:

   ```bash
   docker ps | grep travel-insurance
   ```

2. **View logs**:

   ```bash
   docker logs travel-insurance
   ```

3. **Test health endpoint**:

   ```bash
   curl http://localhost:3000/up
   ```

4. **Open in browser**:
   Navigate to `http://localhost:3000`

### Container Management

**View logs**:

```bash
docker logs travel-insurance
# Follow logs in real-time
docker logs -f travel-insurance
```

**Stop the container**:

```bash
docker stop travel-insurance
```

**Start a stopped container**:

```bash
docker start travel-insurance
```

**Remove the container**:

```bash
docker stop travel-insurance
docker rm travel-insurance
```

**Remove the image**:

```bash
docker rmi travel-insurance
```

### Troubleshooting Docker Issues

1. **Container won't start**:

   ```bash
   # Check logs for errors
   docker logs travel-insurance

   # Check if port is already in use
   lsof -i :3000
   ```

2. **Credentials errors**:

   - Use development mode (shown above) if `config/master.key` doesn't exist
   - Development mode doesn't require encrypted credentials

3. **Database errors**:

   - The entrypoint script automatically runs `db:prepare` and `db:fixtures:load`
   - Check logs to see if database setup completed successfully

4. **Container keeps restarting**:
   ```bash
   # Check exit code
   docker ps -a | grep travel-insurance
   # View full error logs
   docker logs travel-insurance
   ```

### Docker Compose (Optional)

For easier management, you can create a `docker-compose.yml`:

```yaml
version: "3.8"

services:
  web:
    build: .
    ports:
      - "3000:80"
    environment:
      - RAILS_ENV=development
      - SECRET_KEY_BASE=${SECRET_KEY_BASE:-$(rails secret)}
    volumes:
      - db_data:/rails/storage

volumes:
  db_data:
```

Then run:

```bash
docker-compose up -d
docker-compose logs -f
```

## Troubleshooting

### Common Issues

**Database errors:**

```bash
rails db:reset
rails db:fixtures:load
```

**Missing test data:**

```bash
rails db:fixtures:load
# For test environment specifically:
RAILS_ENV=test rails db:fixtures:load
```

Note: Fixtures are located in `test/fixtures/` (RSpec convention). The `rails db:fixtures:load` command will automatically load fixtures from this directory.

**JavaScript not updating prices:**

- Ensure JavaScript is enabled in your browser
- Check browser console for errors
- The form uses `data: { turbo: false }` to prevent Turbo interference

**Tests failing:**

- Ensure database is set up: `rails db:test:prepare`
- Load fixtures: `RAILS_ENV=test rails db:fixtures:load`
- Check that Selenium WebDriver is installed for system tests
- Run tests: `bundle exec rspec`

**Port already in use:**

```bash
# Find process using port 3000
lsof -i :3000
# Kill the process or use a different port
rails server -p 3001
```

## Additional Notes

- The application uses Tailwind CSS for styling (compiled via the asset pipeline)
- Real-time premium updates use vanilla JavaScript (no framework dependencies)
- Test data is provided in `test/fixtures/`, I removed test folder since I am using Rspec and does not want duplicate data - all YAML files are loaded during setup
- Multiple travellers are fully supported - each traveller's age is used in individual premium calculations
- The highest zone destination determines pricing for both base premium and add-ons
