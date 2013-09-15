FactoryGirl.define do
  factory :invoice do
    date_from   { 30.days.ago.beginning_of_day }
    date_to     { 1.day.ago.end_of_day }
  end
  
  trait :prepared do
    workflow_state 'prepared'
  end
  
  trait :settled do
    workflow_state 'settled'
  end
  
  trait :with_remote_invoice do
    freshbooks_invoice_id  431652
    public_link            'https://signalcloud.freshbooks.com/view/yBkg7e8B9CChqJk'
    internal_link          'https://signalcloud.freshbooks.com/invoices/431652'
  end
end
