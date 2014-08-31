class AlertOnTwilioPhoneNumberPricesheetChangeJob < ActiveJob::Base
  queue_as :default

  def perform
    # Find all AccountPlans with original pricesheets
    AccountPlan.where('phone_number_pricesheet is not null').each do |plan|

      original = plan.phone_number_pricesheet
      updated  = original.dup.tap { |sheet| sheet.refresh_from_source }

      diff = original.diff(updated)

      if diff.any?
        TwilioPricesheetChangeMailer.phone_number_pricesheet_changed(plan, diff).deliver_later
      end

    end
  end
  
  def pricesheet
    @pricesheet ||= simplify(Twilio::PhoneNumberPricesheet.parse)
  end
  
  def simplify(pricesheet)
    JSON.load(JSON.dump(pricesheet))
  end

end
