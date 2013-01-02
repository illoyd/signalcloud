require 'spec_helper'

describe 'routing to tickets' do
  #fixtures :accounts, :account_plans, :users, :appliances,

  # Shallow routes
  it 'allows indexing' do
    expect( :get => 'tickets' ).to route_to( controller: 'tickets', action: 'index' )
  end
  it 'allows showing' do
    expect( :get => 'tickets/1' ).to route_to( controller: 'tickets', action: 'show', id: '1' )
  end
#   it 'does not allow new' do
#     pending 'Needs analysis of how to block #show gloming on to "new".'
#     expect( :get => 'tickets/new' ).not_to be_routable
#   end
  it 'does not allow creating' do
    expect( :post => 'tickets' ).not_to be_routable
  end
  it 'does not allow editing' do
    expect( :get => 'tickets/1/edit' ).not_to be_routable
  end
  it 'does not allow updating' do
    expect( :put => 'tickets/1' ).not_to be_routable
  end
  it 'does not allow deleting' do
    expect( :delete => 'tickets/1' ).not_to be_routable
  end
  
  # Nested routes via appliance
  it 'allows listing via appliances' do
    expect( :get => 'appliances/1/tickets' ).to route_to(
      controller: 'tickets',
      action: 'index',
      appliance_id: '1'
    )
  end  

  it 'does not allow showing via appliances' do
    expect( :get => 'appliances/1/tickets/2' ).not_to be_routable
  end

  it 'allows creating via appliances' do
    expect( :post => 'appliances/1/tickets' ).to route_to(
      controller: 'tickets',
      action: 'create',
      appliance_id: '1'
    )
  end

  it 'does not allow updating via appliances' do
    expect( :put => 'appliances/1/tickets/2' ).not_to be_routable
  end

  it 'does not allow deleting via appliances' do
    expect( :delete => 'appliances/2/tickets/1' ).not_to be_routable
  end

  it 'allows forcing ticket status' do
    expect( :post=> 'appliances/1/tickets/2/force' ).to route_to(
      controller: 'tickets',
      action: 'force_status',
      appliance_id: '1',
      id: '2'
    )
  end

end
