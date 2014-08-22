class AddInternalNumberToConversations < ActiveRecord::Migration
  def up
    # Rename all encrypted keys
    rename_column :conversations, :encrypted_internal_number,      :encrypted_old_internal_number
    rename_column :conversations, :encrypted_internal_number_iv,   :encrypted_old_internal_number_iv
    rename_column :conversations, :encrypted_internal_number_salt, :encrypted_old_internal_number_salt

    # Remove not-null constraint
    change_column :conversations, :encrypted_old_internal_number,  :text, null: true

    # Insert new reference to replace old hashes
    add_reference :conversations, :internal_number, index: true
    
    # Update reference based on old hashes
    Conversation.all.each do |conversation|
      conversation.internal_number_id = conversation.organization.phone_numbers.find_by!( number: conversation.old_internal_number ).id
      conversation.save
    end
  end
  
  def down
    # Rename encrypted keys
    rename_column :conversations, :encrypted_old_internal_number,      :encrypted_internal_number
    rename_column :conversations, :encrypted_old_internal_number_iv,   :encrypted_internal_number_iv
    rename_column :conversations, :encrypted_old_internal_number_salt, :encrypted_internal_number_salt
    
    # Remove reference
    remove_reference :conversations, :internal_number

  end
end
