class Numeric
  def seconds_to_words
    # Split parts
    mm, ss = self.divmod(60)            #=> [4515, 21]
    hh, mm = mm.divmod(60)           #=> [75, 15]
    dd, hh = hh.divmod(24)           #=> [3, 3]
    
    # Intelligently select segments - ignore 0 segments
    text = Array.new
    text << '%d %s' % [dd, 'day'.pluralize(dd)] if dd > 0
    text << '%d %s' % [hh, 'hour'.pluralize(hh)] if hh > 0
    text << '%d %s' % [mm, 'minute'.pluralize(mm)] if mm > 0
    text << '%d %s' % [ss, 'second'.pluralize(ss)] if ss > 0
    
    # Pick which general format to reply
    return case text.size
      when 0
        '0 seconds'
      when 1
        text.join
      when 2
        text.join ' and '
      else
        interim = [ text.first( text.length - 1 ).join( ', ' ), text.last ]
        interim.join ', and '
    end
    # return "%d days, %d hours, %d minutes, and %d seconds" % [dd, hh, mm, ss]
  end
end
