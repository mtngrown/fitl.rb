class AddSentimentToLocations < ActiveRecord::Migration[5.0]
  def change
    add_column :locations, :sentiment, :string, default: :neutral
  end
end
