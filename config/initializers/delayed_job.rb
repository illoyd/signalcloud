# config/initializers/delayed_job_config.rb
Delayed::Worker.destroy_failed_jobs = false
#silence_warnings do
  Delayed::Worker.const_set( "SLEEP", 15 )
  Delayed::Worker.const_set( "MAX_ATTEMPTS", 3 )
  Delayed::Worker.const_set( "MAX_RUN_TIME", 5.minutes )
#end
