class AddPricersToAccountPlans < ActiveRecord::Migration
  def up
    change_table :account_plans do |t|
      t.string :phone_number_pricer_class,  null: false, default: 'Pricers::FreePricer'
      t.string :conversation_pricer_class,  null: false, default: 'Pricers::FreePricer'
      t.text   :phone_number_pricer_config
      t.text   :conversation_pricer_config
      
      t.remove :phone_add
      t.remove :call_in_add
      t.remove :sms_in_add
      t.remove :sms_out_add

      t.remove :phone_mult
      t.remove :call_in_mult
      t.remove :sms_in_mult
      t.remove :sms_out_mult
    end
  end

  def down
    change_table :account_plans do |t|
      t.remove :phone_number_pricer_class
      t.remove :conversation_pricer_class
      t.remove :phone_number_pricer_config
      t.remove :conversation_pricer_config
      
      t.decimal :phone_add,    null: false, default: 0, precision: 6, scale: 4
      t.decimal :phone_mult,   null: false, default: 0, precision: 6, scale: 4
      t.decimal :call_in_add,  null: false, default: 0, precision: 6, scale: 4
      t.decimal :call_in_mult, null: false, default: 0, precision: 6, scale: 4
      t.decimal :sms_in_add,   null: false, default: 0, precision: 6, scale: 4
      t.decimal :sms_in_mult,  null: false, default: 0, precision: 6, scale: 4
      t.decimal :sms_out_add,  null: false, default: 0, precision: 6, scale: 4
      t.decimal :sms_out_mult, null: false, default: 0, precision: 6, scale: 4
    end
  end
end
