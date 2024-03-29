class TwilioPricesheetChangeMailer < ActionMailer::Base
  default to: 'hello@signalcloudapp.com', from: "SignalCloud Bot <hello@signalcloudapp.com>"
  
  def phone_number_pricesheet_changed(plan, diff)
    @plan = plan
    @diff = diff
    mail subject: 'Alert! Twilio phone number prices have changed!'
  end
  
  def sms_pricesheet_changed(plan, diff)
    @plan = plan
    @diff = diff
    mail subject: 'Alert! Twilio SMS prices have changed!'
  end
end
