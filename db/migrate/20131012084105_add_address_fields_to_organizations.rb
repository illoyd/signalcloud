class AddAddressFieldsToOrganizations < ActiveRecord::Migration
  def change
    change_table :organizations do |t|
      # Billing fields
      t.string :billing_first_name
      t.string :billing_last_name
      t.string :billing_email
      t.string :billing_line1
      t.string :billing_line2
      t.string :billing_city
      t.string :billing_region
      t.string :billing_postcode
      t.string :billing_country
      t.string :billing_work_phone

      # Contact fields
      t.string :contact_first_name
      t.string :contact_last_name
      t.string :contact_email
      t.string :contact_line1
      t.string :contact_line2
      t.string :contact_city
      t.string :contact_region
      t.string :contact_postcode
      t.string :contact_country
      t.string :contact_work_phone
      
      # Use... flag
      t.boolean :use_billing_as_contact_address, default: true, null: false
    end
  end
end
