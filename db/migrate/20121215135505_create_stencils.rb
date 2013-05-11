class CreateStencils < ActiveRecord::Migration
  def change
    create_table :stencils do |t|
      t.references :organization, null: false
      t.references :phone_book, null: false
      t.string :label, null: false
      t.integer :seconds_to_live, default: 180, null: false
      t.boolean :primary, default: false, null: false
      t.boolean :active, default: true, null: false
      t.string :webhook_uri
      
      t.text :description

      t.text :encrypted_question
      t.string :encrypted_question_iv
      t.string :encrypted_question_salt

      t.text :encrypted_expected_confirmed_answer
      t.string :encrypted_expected_confirmed_answer_iv
      t.string :encrypted_expected_confirmed_answer_salt

      t.text :encrypted_expected_denied_answer
      t.string :encrypted_expected_denied_answer_iv
      t.string :encrypted_expected_denied_answer_salt

      t.text :encrypted_confirmed_reply
      t.string :encrypted_confirmed_reply_iv
      t.string :encrypted_confirmed_reply_salt

      t.text :encrypted_denied_reply
      t.string :encrypted_denied_reply_iv
      t.string :encrypted_denied_reply_salt

      t.text :encrypted_failed_reply
      t.string :encrypted_failed_reply_iv
      t.string :encrypted_failed_reply_salt

      t.text :encrypted_expired_reply
      t.string :encrypted_expired_reply_iv
      t.string :encrypted_expired_reply_salt

      t.timestamps
    end
    
    # Indices
    add_index :stencils, :organization_id
    add_index :stencils, :phone_book_id
    add_index :stencils, :primary
  end
end
