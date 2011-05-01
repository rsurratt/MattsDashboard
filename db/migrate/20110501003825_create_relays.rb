class CreateRelays < ActiveRecord::Migration
  def self.up
    create_table :relays do |t|
      t.integer :user_id
      t.string :name
      t.string :url
      t.integer :dollarsraised_goal
      t.integer :participants_goal
      t.integer :teams_goal

      t.timestamps
    end

    add_index :relays, :user_id
  end

  def self.down
    drop_table :relays
  end
end
