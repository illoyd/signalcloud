require 'spec_helper'

describe 'routing to phone numbers', :type => :routing do

  it 'allows indexing' do
    expect( :get => 'organizations/1/phone_numbers' ).to route_to( controller: 'phone_numbers', action: 'index', organization_id: '1' )
  end

  it 'allows showing' do
    expect( :get => 'organizations/1/phone_numbers/2' ).to route_to( controller: 'phone_numbers', action: 'show', id: '2', organization_id: '1' )
  end
  
#   it 'does not allow new' do
#     pending 'Needs analysis of how to block #show gloming on to "new".'
#     expect( :get => 'phone_numbers/new' ).not_to be_routable
#   end

  it 'allows creating' do
    expect( :post => 'organizations/1/phone_numbers' ).to route_to( controller: 'phone_numbers', action: 'create', organization_id: '1' )
  end

  it 'allows editing' do
    expect( :get => 'organizations/1/phone_numbers/2/edit' ).to route_to( controller: 'phone_numbers', action: 'edit', id: '2', organization_id: '1' )
  end

  it 'allows updating' do
    expect( :put => 'organizations/1/phone_numbers/2' ).to route_to( controller: 'phone_numbers', action: 'update', id: '2', organization_id: '1' )
  end

  it 'does not allow deleting' do
    expect( :delete => 'organizations/1/phone_numbers/2' ).not_to be_routable
  end

end
