class CreateMemberships < ActiveRecord::Migration
  def change
    create_table :memberships do |t|
      t.references :team, index: true
      t.references :user, index: true
      
      t.boolean :administrator,        default: false, null: false
      t.boolean :developer,            default: false, null: false
      t.boolean :billing_liaison,      default: false, null: false
      t.boolean :conversation_manager, default: false, null: false

      t.timestamps null: false
    end
    add_foreign_key :memberships, :teams
    add_foreign_key :memberships, :users
  end
end
