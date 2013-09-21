namespace :jobs do

  desc "Report the delayed_job queue size, as well as count any failures."
  task :count => :environment do
    puts 'Sidekiq queue size: %i.' % Sidekiq::Stats.new.enqueued
    failures = Sidekiq::Stats.new.failed
    if failures == 0
      puts 'Hooray! No failures!' 
    else
      puts 'Oh no! There have been %i failures!' % failures
    end
  end

  desc "Report the error messages of all failed jobs."
  task :failures => [ :environment, :count ] do
    query = Sidekiq::Stats.new.failed
    puts 'No failed jobs.' if query.count == 0

    Sidekiq::RetrySet.new.select do |job|
      puts '=' * 80
      ((klass, method, args) = YAML.load(job.args[0]))
      puts '%i.method( %s )' % [ klass, method, args.joint(', ') ]
    end
  end
  
  namespace :clear do
    desc "Clear all failed jobs from the queue."
    task :failures => :environment do
      puts 'Clearing %i failed jobs...' % Sidekiq::Stats.new.failed
      Sidekiq::RetrySet.new.clear
      puts 'Done.'
    end
  end

end
