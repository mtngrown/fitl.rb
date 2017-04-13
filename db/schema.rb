# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170413024854) do

  create_table "locations", force: :cascade do |t|
    t.string  "name"
    t.string  "population"
    t.string  "terrain"
    t.string  "location_type"
    t.string  "country"
    t.string  "value"
    t.string  "control"
    t.string  "support"
    t.string  "opposition"
    t.integer "us_troop",        default: 0
    t.integer "us_irregular",    default: 0
    t.integer "arvn_troop",      default: 0
    t.integer "arvn_ranger",     default: 0
    t.integer "arvn_police",     default: 0
    t.integer "nva_troop",       default: 0
    t.integer "nva_guerrilla",   default: 0
    t.integer "vc_guerrilla",    default: 0
    t.integer "us_base",         default: 0
    t.integer "arvn_base",       default: 0
    t.integer "vc_base",         default: 0
    t.integer "vc_tunnel_base",  default: 0
    t.integer "nva_base",        default: 0
    t.integer "nva_tunnel_base", default: 0
  end

end
