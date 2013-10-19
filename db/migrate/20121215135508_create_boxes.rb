class CreateBoxes < ActiveRecord::Migration
  def change
    create_table :boxes do |t|
      t.string :workflow_state
      
      # References
      t.references :organization, null: false
      
      # Document
      t.attachment :document
      
      # Information
      t.datetime :start_at
      t.string :label

      t.timestamps
    end
  end
end
