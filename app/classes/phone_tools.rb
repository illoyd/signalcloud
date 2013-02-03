class PhoneTools < Struct

  NANP_CODE = 1
  GB_CODE = 44

  NANP_CANADIAN_CODES = [
    # Alberta
    403, 587, 780, 825,
    # British Columbia
    236, 250, 604, 672, 778,
    # Manitoba
    204, 431,
    # New Brunswick
    506,
    # Newfoundland and Labrador
    709,
    # Nova Scotia
    902,
    # Ontario
    226, 249, 289, 343, 365, 416, 437, 519, 613, 647, 705, 807, 905,
    # Prince Edward Island
    902,
    # Quebec
    418, 438, 450, 514, 579, 581, 819, 873,
    # Saskatchewan
    306, 639,
    # Yukon, Northwest Territories, and Nunavut
    867
  ]
  
  NANP_OTHER_CODES = [
    684, # American Samoa
    264, # Anguila
    268, # Antigua & Barbuda
    242, # The Bahamas
    246, # Barbados
    441, # Bermuda
    284, # British Virgin Islands
    345, # Cayman Islands
    767, # Dominica
    809, 829, 849, # Dominican Republic
    473, # Grenada
    671, # Guam
    876, # Jamaica
    664, # Montserrat
    869, # St Kitts & Nevis
    670, # Northern Mariana Islands
    787, 939, # Puerto Rico
    758, # St. Luca
    784, # St Vincent & the Grenadines
    721, # Sint Martin
    868, # Trinidad & Tobago
    649, # Turks & Caicos Islands
    340 # US Virgin Islands
  ]
  
  #class << self
  
    def self.normalize(number)
      Phony.normalize number
    end
    
    def self.plausible?(number)
      Phony.plausible? number
    end
    
    def self.componentize(number)
      Phony.split(Phony.normalize(number))
    end

    def self.humanize(number)
      Phony.formatted(Phony.normalize(number))
    end
  
    def self.united_states?( number )
      # Fail if not a plausible number
      return false unless Phony.plausible? number
      
      # Divide into components and check for non-Canadian, non-Other area codes
      components = Phony.split( Phony.normalize(number) )
      return components.first.to_i == NANP_CODE && !(NANP_CANADIAN_CODES + NANP_OTHER_CODES).include?( components.second.to_i )
    end
    
    def self.canadian?( number )
      # Fail if not a plausible number
      return false unless Phony.plausible? number
      
      # Divide into components and check for Canadian area codes
      components = Phony.split( Phony.normalize(number) )
      return components.first.to_i == NANP_CODE && NANP_CANADIAN_CODES.include?( components.second.to_i )
    end
    
    def self.other_nanp_country?( number )
      # Fail if not a plausible number
      return false unless Phony.plausible? number
      
      # Divide into components and check for Canadian area codes
      components = Phony.split( Phony.normalize(number) )
      return components.first.to_i == NANP_CODE && NANP_OTHER_CODES.include?( components.second.to_i )
    end
    
    #alias other_nanp_country? not_canadian_or_united_states?

  #end

end
