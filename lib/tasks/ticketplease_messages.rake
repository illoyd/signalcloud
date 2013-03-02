namespace :tp do
  namespace :messages do

    desc "Settle all outstanding messages."
    task :settle => :environment do
      SettleOutstandingMessagesJob.new().perform
    end
    
    namespace :settle do
      task :enqueue => :environment do
        Delayed::Job::enqueue SettleOutstandingMessagesJob.new()
      end
    end

  end
end
