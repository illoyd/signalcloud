module Phony

  CANADIAN_CODES = [
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
  
  OTHER_CODES = [ 684, 264, 268, 242, 246, 441, 284, 345, 767, 809, 829, 849, 473, 671, 876, 808, 664, 869, 670, 787, 939, 758, 784, 721, 868, 649, 340 ]
  
  class << self
  
    def canadian?( number )
      # Fail if not a plausible number
      return false unless Phony.plausible? number
      
      # Divide into components and check for Canadian area codes
      components = Phony.split( Phony.normalize(number) )
      return components.first.to_i == 1 && Phony::CANADIAN_CODES.include?( components.second.to_i )
    end
    
    def not_canadian_or_united_states?( number )
      # Fail if not a plausible number
      return false unless Phony.plausible? number
      
      # Divide into components and check for Canadian area codes
      components = Phony.split( Phony.normalize(number) )
      return components.first.to_i == 1 && Phony::OTHER_CODES.include?( components.second.to_i )
    end

  end
 
end
