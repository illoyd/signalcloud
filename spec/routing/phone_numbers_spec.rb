require 'spec_helper'

describe 'routing to phone numbers' do

  it 'allows indexing' do
    expect( :get => 'phone_numbers' ).to route_to( controller: 'phone_numbers', action: 'index' )
  end

  it 'allows showing' do
    expect( :get => 'phone_numbers/1' ).to route_to( controller: 'phone_numbers', action: 'show', id: '1' )
  end
  
  it 'allows searching' do
    #pending 'Needs analysis of how to block #show gloming on to "search".'
    expect( :get => '/phone_numbers/search/US' ).to route_to( 'phone_numbers#search', country: 'US', constraint: { 'country' => /(US|CA|GB)/ } )
    expect( :get => '/phone_numbers/search/CA' ).to route_to( 'phone_numbers#search', country: 'CA', constraint: { 'country' => /(US|CA|GB)/ } )
    expect( :get => '/phone_numbers/search/GB' ).to route_to( 'phone_numbers#search', country: 'GB', constraint: { 'country' => /(US|CA|GB)/ } )
    #expect( :get => '/phone_numbers/search' ).to route_to( 'phone_numbers#search', country: 'US' )
  end
  
  it 'allows buying' do
    expect( :post => 'phone_numbers/buy' ).to route_to( controller: 'phone_numbers', action: 'buy' )
  end
  
#   it 'does not allow new' do
#     pending 'Needs analysis of how to block #show gloming on to "new".'
#     expect( :get => 'phone_numbers/new' ).not_to be_routable
#   end

  it 'does not allow creating' do
    expect( :post => 'phone_numbers' ).not_to be_routable
  end

  it 'does not allow editing' do
    expect( :get => 'phone_numbers/1/edit' ).not_to be_routable
  end

  it 'does not allow updating' do
    expect( :put => 'phone_numbers/1' ).not_to be_routable
  end

  it 'does not allow deleting' do
    expect( :delete => 'phone_numbers/1' ).not_to be_routable
  end

end
