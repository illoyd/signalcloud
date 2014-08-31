class ChangeAccountPlanPricerColumns < ActiveRecord::Migration
  def change
    change_table :account_plans do |t|
      t.rename :phone_number_pricer_config, :phone_number_pricesheet
      t.rename :conversation_pricer_config, :conversation_pricesheet
    end
  end
end
