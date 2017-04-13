# frozen_string_literal: true

class Location < ActiveRecord::Migration[5.0]
  def change
    create_table :locations do |t|
      t.string :name
      t.string :population
      t.string :terrain
      t.string :location_type
      t.string :country
      t.string :value
      t.string :control
      t.integer :support,         default: 0
      t.integer :us_troop,        default: 0
      t.integer :us_irregular,    default: 0
      t.integer :arvn_troop,      default: 0
      t.integer :arvn_ranger,     default: 0
      t.integer :arvn_police,     default: 0
      t.integer :nva_troop,       default: 0
      t.integer :nva_guerrilla,   default: 0
      t.integer :vc_guerrilla,    default: 0
      t.integer :us_base,         default: 0
      t.integer :arvn_base,       default: 0
      t.integer :vc_base,         default: 0
      t.integer :vc_tunnel_base,  default: 0
      t.integer :nva_base,        default: 0
      t.integer :nva_tunnel_base, default: 0
    end
  end
end
