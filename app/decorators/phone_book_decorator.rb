class PhoneBookDecorator < ApplicationDecorator
  delegate_all

  decorates_association :phone_numbers, with: PhoneNumberDecorator
  decorates_association :phone_book_entries, with: PhoneBookEntryDecorator

  def display_name
    name || 'New'
  end
  
  def add_phone_book_entry_button
    new_phone_book_entry.new_button
  end
  
  def add_phone_book_entry_modal
    new_phone_book_entry.edit_modal
  end
  
  def new_phone_book_entry
    @new_phone_book_entry ||= PhoneBookEntryDecorator.decorate(model.phone_book_entries.build)
  end
  
end
