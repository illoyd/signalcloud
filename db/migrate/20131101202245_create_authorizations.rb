class CreateAuthorizations < ActiveRecord::Migration
  def change
    create_table :authorizations do |t|
      t.string :type

      t.references :user
      
      t.string :oauth_hash
      
      t.text :encrypted_username
      t.string :encrypted_username_salt
      t.string :encrypted_username_iv

      t.text :encrypted_uid
      t.string :encrypted_uid_salt
      t.string :encrypted_uid_iv

      t.text :encrypted_token
      t.string :encrypted_token_salt
      t.string :encrypted_token_iv

      t.text :encrypted_secret
      t.string :encrypted_secret_salt
      t.string :encrypted_secret_iv
      
      t.text :encrypted_refresh_token
      t.string :encrypted_refresh_token_salt
      t.string :encrypted_refresh_token_iv

      t.datetime :expires_at     

      t.timestamps
    end

    add_index :authorizations, [ :type, :user_id ], unique: true
  end
end
