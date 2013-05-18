class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      
      t.boolean :system_admin, null: false, default: false

      t.timestamps
    end
  end
end
