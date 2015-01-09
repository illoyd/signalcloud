class PostcodeValidator < ActiveModel::EachValidator
  include GoingPostal

  def validate_each(record, attribute, value)
    unless value.plausible_postcode?
      record.errors[attribute] << (options[:message] || "is not a plausible postcode")
    end
  end
end