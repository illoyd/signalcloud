require 'spec_helper'

describe "Walkabout" do
  let!(:user)          { create(:user, user_roles: [ UserRole.create(organization: organization, roles: UserRole::ROLES) ]) }
  let!(:organization)  { create(:organization, :test_twilio) }
  let!(:comm_gateway)  { organization.communication_gateways.first }
  let!(:phone_number)  { create :phone_number, organization: organization, communication_gateway: comm_gateway }
  let!(:phone_book)    { create :phone_book, organization: organization }
  let!(:stencil)       { create :stencil, organization: organization, phone_book: phone_book }
  let!(:conversation)  { create :conversation, stencil: stencil }
  let!(:message)       { create :message, conversation: conversation }
  let!(:ledger_entry)  { create :ledger_entry, item: message }

  before(:each) { sign_in(user) }

  it 'GETs /users/:id' do
    get '/users/%i' % [ user.id ]
    response.status.should eq(200)
  end

  it 'GETs /organizations' do
    get '/organizations'
    response.status.should eq(200)
  end

  it 'GETs /organizations/:id' do
    get '/organizations/%i' % [ organization.id ]
    response.status.should eq(200)
  end

  it 'GETs /organizations/:id/users' do
    get '/organizations/%i/users' % [ organization.id ]
    response.status.should eq(200)
  end

  it 'GETs /organizations/:id/stencils' do
    get '/organizations/%i/stencils' % [ organization.id ]
    response.status.should eq(200)
  end

  it 'GETs /organizations/:id/stencils/new' do
    get '/organizations/%i/stencils/new' % [ organization.id ]
    response.status.should eq(200)
  end

  it 'GETs /organizations/:id/stencils/:id' do
    get '/organizations/%i/stencils/%i' % [ organization.id, stencil.id ]
    response.status.should eq(200)
  end

  it 'GETs /organizations/:id/stencils/:id/edit' do
    get '/organizations/%i/stencils/%i/edit' % [ organization.id, stencil.id ]
    response.status.should eq(200)
  end

  it 'GETs /organizations/:id/conversations' do
    get '/organizations/%i/conversations' % [ organization.id ]
    response.status.should eq(200)
  end

  it 'GETs /organizations/:id/conversations/new' do
    get '/organizations/%i/conversations' % [ organization.id ]
    response.status.should eq(200)
  end

  it 'GETs /organizations/:id/conversations/:id' do
    get '/organizations/%i/conversations/%i' % [ organization.id, conversation.id ]
    response.status.should eq(200)
  end

  it 'GETs /organizations/:id/phone_numbers' do
    get '/organizations/%i/phone_numbers' % [ organization.id ]
    response.status.should eq(200)
  end

  it 'GETs /organizations/:id/phone_numbers/:id' do
    get '/organizations/%i/phone_numbers/%i' % [ organization.id, phone_number.id ]
    response.status.should eq(200)
  end

  it 'GETs /organizations/:id/phone_books' do
    get '/organizations/%i/phone_books' % [ organization.id ]
    response.status.should eq(200)
  end

  it 'GETs /organizations/:id/phone_books/new' do
    get '/organizations/%i/phone_books' % [ organization.id ]
    response.status.should eq(200)
  end

  it 'GETs /organizations/:id/phone_books/:id' do
    get '/organizations/%i/phone_books/%i' % [ organization.id, phone_book.id ]
    response.status.should eq(200)
  end

  it 'GETs /organizations/:id/phone_books/:id/edit' do
    get '/organizations/%i/phone_books/%i/edit' % [ organization.id, phone_book.id ]
    response.status.should eq(200)
  end

  it 'GETs /organizations/:id/ledger_entries' do
    get '/organizations/%i/ledger_entries' % [ organization.id ]
    response.status.should eq(200)
  end

  it 'GETs /organizations/:id/ledger_entries/:id' do
    get '/organizations/%i/ledger_entries/%i' % [ organization.id, ledger_entry.id ]
    response.status.should eq(200)
  end

end
