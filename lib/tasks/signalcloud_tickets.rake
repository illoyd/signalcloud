namespace :tp do
  namespace :conversations do

    desc "Settle all outstanding conversations."
    task :settle => :environment do
      SettleOutstandingConversationsJob.new().perform
    end
    
    namespace :settle do
      desc "Enqueue a job to settle all outstanding conversations."
      task :enqueue => :environment do
        SettleOutstandingConversationsJob.perform_async
      end
    end

  end
end
