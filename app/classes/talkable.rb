module Talkable

  def logger
    @logger ||= if defined?(Rails)
        Rails.logger
      elsif defined?(RAILS_DEFAULT_LOGGER)
        RAILS_DEFAULT_LOGGER
      end
  end
  
  def say( text, level = Logger::INFO )
    text = "[#{self.class.name}(#{self.ticket_id})] #{text}"
    puts text unless self.quiet
    self.logger.add level, "#{Time.now.strftime('%FT%T%z')}: #{text}" if self.logger
  end

end