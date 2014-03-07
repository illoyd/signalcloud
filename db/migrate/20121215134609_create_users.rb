class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.string :nickname
      
      t.boolean :system_admin, null: false, default: false

      t.timestamps
    end
  end
end
