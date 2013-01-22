namespace :invoices do
  desc "Enqueue the invoice enqueue-er job."
  task :enqueue => :environment do
    Delayed::Job::enqueue EnqueueCreateInvoiceJobsJob.new( DateTime.yesterday.end_of_day )
  end
end
