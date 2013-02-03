module Talkable

  def say( text, level = Logger::DEBUG )
    text = "[#{self.class.name}(#{self.ticket_id})] #{text}"
    puts text unless self.quiet
    Delayed::Worker.logger.add( level, "#{Time.now.strftime('%FT%T%z')}: #{text}" ) if Delayed::Worker.logger
  end

end
