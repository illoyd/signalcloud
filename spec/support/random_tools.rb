def rand_datetime(from, to=Time.now)
  Time.at(rand_in_range(from.to_f, to.to_f))
end

def rand_datetime_lastmonth(from=nil, to=nil)
  from ||= 1.month.ago.beginning_of_month
  to ||= from.end_of_month
  Time.at rand_in_range(from.to_f, to.to_f)
end

def rand_in_range(from, to)
  rand * (to - from) + from
end

def rand_f( min, max )
  rand * (max-min) + min
end

def rand_i( min, max )
  min = min.to_i
  max = max.to_i
  rand(max-min) + min
end

def random_us_number()
  '1%03d%03d%04d' % [ rand_i(201, 799), rand_i(100, 999), rand_i(0001, 9999) ]
end

def random_ca_number()
  '1%03d%03d%04d' % [ rand_i(201, 799), rand_i(100, 999), rand_i(0001, 9999) ]
end

def random_uk_number()
  '44%04d%03d%03d' % [ rand_i(2000, 9999), rand_i(000, 999), rand_i(000, 999) ]
end

def random_cost( min=0.01, max=99.99, round=2 )
  rand_f(min, max).round(round)
end

alias random_price random_cost
