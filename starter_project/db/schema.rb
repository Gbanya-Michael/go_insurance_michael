# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2024_08_24_100341) do
  create_table "ages", force: :cascade do |t|
    t.integer "age_maximum", null: false
    t.integer "age_minimum", null: false
    t.datetime "created_at", null: false
    t.decimal "multiplier", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["age_maximum"], name: "index_ages_on_age_maximum"
    t.index ["age_minimum"], name: "index_ages_on_age_minimum"
    t.index ["multiplier"], name: "index_ages_on_multiplier"
  end

  create_table "covers", force: :cascade do |t|
    t.string "cover_type", null: false
    t.datetime "created_at", null: false
    t.string "label", null: false
    t.decimal "multiplier", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["cover_type"], name: "index_covers_on_cover_type"
    t.index ["label"], name: "index_covers_on_label"
    t.index ["multiplier"], name: "index_covers_on_multiplier"
  end

  create_table "destinations", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.decimal "cruise_add_on_amount", precision: 10, scale: 2, null: false
    t.string "label", null: false
    t.decimal "multiplier", null: false
    t.decimal "ski_per_day_amount", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.integer "zone", null: false
    t.index ["code"], name: "index_destinations_on_code"
    t.index ["cruise_add_on_amount"], name: "index_destinations_on_cruise_add_on_amount"
    t.index ["multiplier"], name: "index_destinations_on_multiplier"
    t.index ["ski_per_day_amount"], name: "index_destinations_on_ski_per_day_amount"
    t.index ["zone"], name: "index_destinations_on_zone"
  end

  create_table "durations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "maximum_days", null: false
    t.integer "minimum_days", null: false
    t.decimal "multiplier", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["maximum_days"], name: "index_durations_on_maximum_days"
    t.index ["minimum_days"], name: "index_durations_on_minimum_days"
    t.index ["multiplier"], name: "index_durations_on_multiplier"
  end

  create_table "excesses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "label", null: false
    t.decimal "multiplier", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.decimal "value", precision: 10, scale: 2, null: false
    t.index ["label"], name: "index_excesses_on_label"
    t.index ["multiplier"], name: "index_excesses_on_multiplier"
    t.index ["value"], name: "index_excesses_on_value"
  end

  create_table "premia", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "label", null: false
    t.decimal "multiplier", precision: 24, scale: 14
    t.string "premium_type", null: false
    t.datetime "updated_at", null: false
    t.index ["label"], name: "index_premia_on_label"
    t.index ["multiplier"], name: "index_premia_on_multiplier"
    t.index ["premium_type"], name: "index_premia_on_premium_type"
  end

  create_table "quotes", force: :cascade do |t|
    t.integer "age", null: false
    t.integer "cover_id", null: false
    t.datetime "created_at", null: false
    t.boolean "cruise", default: false
    t.date "end_date", null: false
    t.integer "excess_id", null: false
    t.boolean "snow", default: false
    t.date "snow_end_date"
    t.date "snow_start_date"
    t.date "start_date", null: false
    t.integer "trip_type_id", null: false
    t.datetime "updated_at", null: false
    t.index ["age"], name: "index_quotes_on_age"
    t.index ["cover_id"], name: "index_quotes_on_cover_id"
    t.index ["cruise"], name: "index_quotes_on_cruise"
    t.index ["end_date"], name: "index_quotes_on_end_date"
    t.index ["excess_id"], name: "index_quotes_on_excess_id"
    t.index ["snow"], name: "index_quotes_on_snow"
    t.index ["snow_end_date"], name: "index_quotes_on_snow_end_date"
    t.index ["snow_start_date"], name: "index_quotes_on_snow_start_date"
    t.index ["start_date"], name: "index_quotes_on_start_date"
    t.index ["trip_type_id"], name: "index_quotes_on_trip_type_id"
  end

  create_table "quotes_to_destinations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "destination_id", null: false
    t.integer "quote_id", null: false
    t.datetime "updated_at", null: false
    t.index ["destination_id"], name: "index_quotes_to_destinations_on_destination_id"
    t.index ["quote_id"], name: "index_quotes_to_destinations_on_quote_id"
  end

  create_table "trip_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "label", null: false
    t.decimal "multiplier", precision: 10, scale: 2
    t.string "trip_type", null: false
    t.datetime "updated_at", null: false
    t.index ["label"], name: "index_trip_types_on_label"
    t.index ["multiplier"], name: "index_trip_types_on_multiplier"
    t.index ["trip_type"], name: "index_trip_types_on_trip_type"
  end

  add_foreign_key "quotes", "covers"
  add_foreign_key "quotes", "excesses"
  add_foreign_key "quotes", "trip_types"
  add_foreign_key "quotes_to_destinations", "destinations"
  add_foreign_key "quotes_to_destinations", "quotes"
end
