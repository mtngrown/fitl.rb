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
      t.integer :support
      t.integer :us_troop
      t.integer :us_irregular
      t.integer :arvn_troop
      t.integer :arvn_ranger
      t.integer :arvn_police
      t.integer :nva_troop
      t.integer :nva_guerrilla
      t.integer :vc_guerrilla
      t.integer :us_base
      t.integer :arvn_base
      t.integer :vc_base
      t.integer :vc_tunnel_base
      t.integer :nva_base
      t.integer :nva_tunnel_base
    end
  end
end
