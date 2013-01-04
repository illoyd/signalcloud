##
# Verify that a phone number is plausible
class PhoneNumberValidator < ActiveModel::EachValidator

  def validate_each( record, attribute, value )
    unless Phony.plausible? value
     record.errors[attribute] << (options[:message] || "is not a plausible phone number")
    end
  end

end
