class CreateParameters < ActiveRecord::Migration
  def self.up
    create_table :parameters do |t|
      t.column :name, :string
      t.column :value, :string
      t.timestamps
    end
  end

  def self.down
    drop_table :parameters
  end
end
