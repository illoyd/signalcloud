class CreateAccountPlans < ActiveRecord::Migration
  def change
    create_table :account_plans do |t|
      t.string :label, null: false
      t.boolean :default, null: false, default: false
      t.integer :plan_kind, null: false, default: AccountPlan::CREDIT, limit: 1
      t.decimal :month, null: false, default: 0, precision: 6, scale: 4
      t.decimal :phone_add, null: false, default: 0, precision: 6, scale: 4
      t.decimal :phone_mult, null: false, default: 0, precision: 6, scale: 4
      t.decimal :call_in_add, null: false, default: 0, precision: 6, scale: 4
      t.decimal :call_in_mult, null: false, default: 0, precision: 6, scale: 4
      t.decimal :sms_in_add, null: false, default: 0, precision: 6, scale: 4
      t.decimal :sms_in_mult, null: false, default: 0, precision: 6, scale: 4
      t.decimal :sms_out_add, null: false, default: 0, precision: 6, scale: 4
      t.decimal :sms_out_mult, null: false, default: 0, precision: 6, scale: 4

      t.timestamps
    end
  end
end
