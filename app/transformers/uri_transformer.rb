class URITransformer

  def self.call(value)
    URI.parse(value) rescue value
  end

end
