class AlertOnTwilioSmsPricesheetChangeJob < ActiveJob::Base
  queue_as :default

  def perform
    # Find all AccountPlans with original pricesheets
    AccountPlan.where('original_conversation_pricesheet is not null').each do |plan|
      original = simplify(plan.original_conversation_pricesheet)
      diff = HashDiff.diff(original, pricesheet)
      if diff.any?
        TwilioPricesheetChangeMailer.sms_pricesheet_changed(plan, diff).deliver_later
      end
    end
  end
  
  def pricesheet
    @pricesheet ||= simplify(Twilio::SmsPricesheet.parse)
  end
  
  def simplify(pricesheet)
    JSON.load(JSON.dump(pricesheet))
  end

end
