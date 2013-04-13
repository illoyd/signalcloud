require 'spec_helper'

describe 'routing to tickets' do
  #fixtures :accounts, :account_plans, :users, :stencils,

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
  
  # Nested routes via stencil
  it 'allows listing via stencils' do
    expect( :get => 'stencils/1/tickets' ).to route_to(
      controller: 'tickets',
      action: 'index',
      stencil_id: '1'
    )
  end  

  it 'does not allow showing via stencils' do
    expect( :get => 'stencils/1/tickets/2' ).not_to be_routable
  end

  it 'allows creating via stencils' do
    expect( :post => 'stencils/1/tickets' ).to route_to(
      controller: 'tickets',
      action: 'create',
      stencil_id: '1'
    )
  end

  it 'does not allow updating via stencils' do
    expect( :put => 'stencils/1/tickets/2' ).not_to be_routable
  end

  it 'does not allow deleting via stencils' do
    expect( :delete => 'stencils/2/tickets/1' ).not_to be_routable
  end

  it 'allows forcing ticket status' do
    expect( :post=> 'stencils/1/tickets/2/force' ).to route_to(
      controller: 'tickets',
      action: 'force_status',
      stencil_id: '1',
      id: '2'
    )
  end

end
