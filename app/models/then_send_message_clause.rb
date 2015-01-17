class ThenSendMessageClause < ThenClause
  
  store_accessor :settings, :message
  
  validates_presence_of :message

  normalize_attributes :message  
end
