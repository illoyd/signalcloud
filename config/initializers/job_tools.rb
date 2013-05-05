
module JobTools

  ##
  # Hash containing the default job priorities for each 'kind' of job.
  JOB_PRIORITIES = {
    # Create account jobs
    CreateTwilioAccountJob: 8,
    CreateFreshBooksClientJob: 8,
  
    # Handle inbound messages
    InboundMessageJob: 4,
  
    # 
    UpdateMessageStatusJob: 7,
    SendWebhookReplyJob: 5,
  
    # Send messages
    SendConversationChallengeJob: 8,
    SendConversationReplyJob: 8
    
    # Invoicing and reporting
    # TODO
  }.with_indifferent_access.freeze

  ##
  # Standard priority for any job without a saved priority flag.
  DEFAULT_PRIORITY = 9

  ## Find the priority for the given job.
  def self.priority_for_job( job )
    JOB_PRIORITIES.fetch( job.class.name, DEFAULT_PRIORITY )
  end

  ##
  # Enqueue the job into the job queue with the appriopriate priority.
  def self.enqueue( job, options={} )
    options[:priority] ||= priority_for_job(job)
    Delayed::Job.enqueue job, options
  end

end
