##
# Verify that a phone number is plausible
class PhoneNumberValidator < ActiveModel::EachValidator

  def validate_each( record, attribute, value )
    value = value.phone_number if value.is_a?(MiniPhoneNumber)
    unless Country.plausible_phone_number?(value)
     record.errors[attribute] << (options[:message] || "is not a plausible phone number")
    end
  end
  
end
