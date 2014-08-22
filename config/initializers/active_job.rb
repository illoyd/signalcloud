module ActiveJob
  module QueueAdapters
    class ArrayAdapter

      class << self
        def enqueue(job, *args)
          enqueue_at(job, nil, *args)
        end

        def enqueue_at(job, timestamp, *args)
          internal_queue[job.queue_name] << JobDetails.new(job, timestamp, *args)
        end
        
        def work(queue_name = ActiveJob::Base.queue_name, count = nil, force_run = false)
          jobs_to_execute = internal_queue[queue_name]
          jobs_to_execute = jobs_to_execute.first(count) if count
          jobs_to_execute.each { |job| job.execute(force_run) }
        end
        
        def internal_queue
          @@queue ||= Hash.new { |hash, key| hash[key] = [] }
        end
      end

      class JobDetails
        attr_reader :job, :args, :timestamp

        def initialize(job, timestamp, *args)
          @job       = job
          @args      = args
          @timestamp = timestamp
        end
        
        def execute(force_run = false)
          job.new.execute(*args) if (force_run || timestamp.nil? || timestamp <= Time.now)
        end
      end
    end
  end
end

# Configure active job
# TODO Move to standard configuration in 4.2
require 'active_job'
ActiveJob::Base.queue_adapter = Rails.env.test? ? ActiveJob::QueueAdapters::ArrayAdapter : :sidekiq
ActiveJob::Base.queue_base_name = nil
ActiveJob::Base.queue_name = 'default'
