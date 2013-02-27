namespace :jobs do
  desc "Return queue size."

  task :count => :environment do
    puts 'Delayed::Job queue size: %i.' % Delayed::Job.count
    failures = Delayed::Job.where( 'last_error is not null' ).count
    if failures == 0
      puts 'Hooray! No failures!' 
    else
      puts 'Oh no! There have been %i failures!' % failures
    end
  end

  task :failures => :environment do
    query = Delayed::Job.where( 'last_error is not null' )
    puts 'No failed jobs.' if query.count == 0

    query.each do |job|
      puts '%i) %s' % [ job.id, job.failed_at ]
      puts job.last_error
    end
  end

end
