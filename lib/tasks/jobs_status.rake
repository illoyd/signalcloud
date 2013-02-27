namespace :jobs do

  desc "Report the delayed_job queue size, as well as count any failures."
  task :count => :environment do
    puts 'Delayed::Job queue size: %i.' % Delayed::Job.count
    failures = Delayed::Job.where( 'last_error is not null' ).count
    if failures == 0
      puts 'Hooray! No failures!' 
    else
      puts 'Oh no! There have been %i failures!' % failures
    end
  end

  desc "Report the error messages of all failed jobs."
  task :failures => [ :environment, :count ] do
    query = Delayed::Job.where( 'last_error is not null' )
    puts 'No failed jobs.' if query.count == 0

    query.each do |job|
      puts '=' * 80
      puts '%i) %s' % [ job.id, job.failed_at ]
      puts job.last_error
    end
  end
  
  namespace :clear do
    desc "Clear all failed jobs from the queue."
    task :failures => :environment do
      puts 'Clearing %i failed jobs...' % Delayed::Job.where( 'last_error is not null' ).count
      Delayed::Job.destroy_all( 'last_error is not null' )
      puts 'Done.'
    end
  end

end
