namespace :tp do
  namespace :tickets do

    desc "Settle all outstanding tickets."
    task :settle => :environment do
      SettleOutstandingTicketsJob.new().perform
    end
    
    namespace :settle do
      desc "Enqueue a job to settle all outstanding tickets."
      task :enqueue => :environment do
        Delayed::Job::enqueue SettleOutstandingTicketsJob.new()
      end
    end

  end
end
