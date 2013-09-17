module Talkable

  attr_writer :quiet
  
  def quiet
    @quiet.nil? ? true : @quiet
  end

  def say( text, level = Logger::DEBUG )
    text = "[#{self.class.name}] #{text}"
    puts text unless self.quiet
    logger.add( level, "#{Time.now.strftime('%FT%T%z')}: #{text}" ) if logger
  end

end
