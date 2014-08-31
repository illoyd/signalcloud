namespace :scheduler do
  desc "Enqueue jobs to test pricesheets"
  task :pricesheet_alerts => :environment do
    AlertOnTwilioSmsPricesheetChangeJob.enqueue
    AlertOnTwilioPhoneNumberPricesheetChangeJob.enqueue
  end
end