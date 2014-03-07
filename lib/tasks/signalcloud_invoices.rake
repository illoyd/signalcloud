namespace :tp do
  namespace :invoices do
    desc "Enqueue the invoice enqueue-er job."
    task :enqueue => :environment do
      EnqueueCreateInvoiceJobsJob.perform_async( DateTime.yesterday.end_of_day )
    end
  end
end
