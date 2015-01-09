class TimeTransformer

  def self.call(value)
    Time.parse(value) rescue value
  end

end
