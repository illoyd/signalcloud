class PhoneBook < ActiveRecord::Base
  belongs_to :team, inverse_of: :phone_books
  has_many :phone_book_entries, inverse_of: :phone_book
  has_many :phone_numbers, through: :phone_book_entries

  normalize_attributes :name, :description

  include Workflow
  workflow do
    state :active do
      event :deactivate, transitions_to: :inactive
    end
    state :inactive do
      event :activate, transitions_to: :active
    end
  end

end
