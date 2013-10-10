class CreateBoxes < ActiveRecord::Migration
  def change
    create_table :boxes do |t|
      t.workflow_state
      
      # References
      t.references :organization, null: false
      
      # Information
      t.datetime :start_at
      t.string :label

      t.timestamps
    end
  end
end
