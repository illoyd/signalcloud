class ThenSetStatusClause < ThenClause
  
  store_accessor :settings, :status
  
  validates_presence_of :status

  normalize_attributes :status
end
