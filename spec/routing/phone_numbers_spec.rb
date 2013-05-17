require 'spec_helper'

describe 'routing to phone numbers' do

  it 'allows indexing' do
    expect( :get => 'organizations/1/phone_numbers' ).to route_to( controller: 'phone_numbers', action: 'index', organization_id: '1' )
  end

  it 'allows showing' do
    expect( :get => 'organizations/1/phone_numbers/1' ).to route_to( controller: 'phone_numbers', action: 'show', id: '1', organization_id: '1' )
  end
  
  it 'allows searching' do
    #pending 'Needs analysis of how to block #show gloming on to "search".'
    expect( :get => 'organizations/1/phone_numbers/search/US' ).to route_to( 'phone_numbers#search', country: 'US', organization_id: '1', constraint: { 'country' => /(US|CA|GB)/ } )
    expect( :get => 'organizations/1/phone_numbers/search/CA' ).to route_to( 'phone_numbers#search', country: 'CA', organization_id: '1', constraint: { 'country' => /(US|CA|GB)/ } )
    expect( :get => 'organizations/1/phone_numbers/search/GB' ).to route_to( 'phone_numbers#search', country: 'GB', organization_id: '1', constraint: { 'country' => /(US|CA|GB)/ } )
    #expect( :get => '/phone_numbers/search' ).to route_to( 'phone_numbers#search', country: 'US' )
  end
  
  it 'allows buying' do
    expect( :post => 'organizations/1/phone_numbers/buy' ).to route_to( controller: 'phone_numbers', action: 'buy', organization_id: '1' )
  end
  
#   it 'does not allow new' do
#     pending 'Needs analysis of how to block #show gloming on to "new".'
#     expect( :get => 'phone_numbers/new' ).not_to be_routable
#   end

  it 'does not allow creating' do
    expect( :post => 'organizations/1/phone_numbers' ).not_to be_routable
  end

  it 'allows editing' do
    expect( :get => 'organizations/1/phone_numbers/1/edit' ).to route_to( controller: 'phone_numbers', action: 'edit', id: '1', organization_id: '1' )
  end

  it 'allows updating' do
    expect( :put => 'organizations/1/phone_numbers/1' ).to route_to( controller: 'phone_numbers', action: 'update', id: '1', organization_id: '1' )
  end

  it 'does not allow deleting' do
    expect( :delete => 'organizations/1/phone_numbers/1' ).not_to be_routable
  end

end
