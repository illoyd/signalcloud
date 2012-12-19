class Transaction < ActiveRecord::Base
  attr_accessible :item, :narrative, :value
end
