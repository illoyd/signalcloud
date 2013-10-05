class CreateBoxes < ActiveRecord::Migration
  def change
    create_table :boxes do |t|
    
      t.references :organization, null: false
      t.datetime :start_at
      t.string :label

      t.timestamps
    end
  end
end
