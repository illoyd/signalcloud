##
# Breadcrumb configuration file

# Root crumb
crumb :root do
  link iconify('Organizations', :organizations), organizations_path
end

# Organization crumbs
crumb :organization do |organization|
  if organization.new_record?
    link 'New', new_organization_path
  else
    link organization.label, organization_path(organization)
  end
end

# Conversation crumbs
crumb :organization_conversations do |organization|
  link "Conversations", organization_conversations_path(organization)
  parent :organization, organization
end

crumb :conversation do |conversation|
  if conversation.new_record?
    link 'New', nil
  else
    link conversation.id, organization_conversation_path(conversation.organization, conversation)
  end
  parent :organization_conversations, conversation.organization
end

# Stencil crumbs
crumb :organization_stencils do |organization|
  link "Stencils", organization_stencils_path(organization)
  parent :organization, organization
end

crumb :stencil do |stencil|
  if stencil.new_record?
    link 'New', nil
  else
    link stencil.label, organization_stencil_path(stencil.organization, stencil)
  end
  parent :organization_stencils, stencil.organization
end


# Phone Book crumbs
crumb :organization_phone_books do |organization|
  link "Phone Books", organization_phone_books_path(organization)
  parent :organization, organization
end

crumb :phone_book do |phone_book|
  if phone_book.new_record?
    link 'New', nil
  else
    link phone_book.label, organization_phone_book_path(phone_book.organization, phone_book)
  end
  parent :organization_phone_books, phone_book.organization
end


# Phone Number crumbs
crumb :organization_phone_numbers do |organization|
  link "Phone Numbers", organization_phone_numbers_path(organization)
  parent :organization, organization
end

crumb :phone_number do |phone_number|
  if phone_number.new_record?
    link 'New', nil
  else
    link humanize_phone_number(phone_number.number), organization_phone_number_path(phone_number.organization, phone_number)
  end
  parent :organization_phone_numbers, phone_number.organization
end

crumb :organization_phone_number_search do |organization|
  link 'Search', nil
  parent :organization, organization
end


# Ledger Entry crumbs
crumb :organization_ledger_entries do |organization|
  link "Ledger Entries", organization_ledger_entries_path(organization)
  parent :organization, organization
end

crumb :ledger_entry do |ledger_entry|
  if ledger_entry.new_record?
    link 'New', nil
  else
    link ledger_entry.id, organization_ledger_entry_path(ledger_entry.organization, ledger_entry)
  end
  parent :organization_ledger_entries, ledger_entry.organization
end


# User crumbs
crumb :organization_users do |organization|
  link "Users", organization_users_path(organization)
  parent :organization, organization
end

crumb :user do |organization, user|
  if user.new_record?
    link 'New', nil
  else
    link user.name, organization_user_path(organization, user)
  end
  parent :organization_users, organization
end
