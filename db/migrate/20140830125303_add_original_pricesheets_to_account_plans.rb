class AddOriginalPricesheetsToAccountPlans < ActiveRecord::Migration
  def change
    change_table :account_plans do |t|
      t.text :original_phone_number_pricesheet
      t.text :original_conversation_pricesheet
    end
  end
end
