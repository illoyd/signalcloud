class IfResponseClause < IfClause
  
  store_accessor :settings, :response
  
  validates_presence_of :response

  normalize_attributes :response
end
