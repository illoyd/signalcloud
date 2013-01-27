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

def random_cost( min=0.01, max=100.99 )
  '%0.2f' % rand_f(0.01, 100.99)
end

FactoryGirl.define do

  factory :phone_number do
    number                      { random_us_number() }
    twilio_phone_number_sid     { 'PN' + SecureRandom.hex(16) }
    provider_cost               { random_cost() }
    our_cost                    { random_cost() }
    
    factory :valid_phone_number do
      number                    { Twilio::VALID_NUMBER }
    end
    
    factory :invalid_phone_number do
      number                    { Twilio::INVALID_NUMBER }
    end
    
    factory :uk_phone_number do
      number                    { random_uk_number() }
    end
    
    factory :ca_phone_number do
      number                    { random_ca_number() }
    end
  end

end
