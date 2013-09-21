namespace :tp do
  namespace :messages do

    desc "Settle all outstanding messages."
    task :settle => :environment do
      SettleOutstandingMessagesJob.new().perform
    end
    
    namespace :settle do
      desc "Enqueue a job to settle all outstanding messages."
      task :enqueue => :environment do
        SettleOutstandingMessagesJob.perform_async()
      end
    end

  end
end
