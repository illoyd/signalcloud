class CreateTeams < ActiveRecord::Migration
  def change
    create_table :teams do |t|
      t.references :user, index: true
      t.string :workflow_state
      t.string :name
      t.text :description

      t.timestamps null: false
    end
    add_index :teams, :workflow_state
    add_foreign_key :teams, :users
  end
end
