class IfClause < ActiveRecord::Base
  belongs_to :parent, polymorphic: true
  
  store :settings
end
