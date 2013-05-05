require 'spec_helper'

describe 'routing to conversations' do
  #fixtures :accounts, :account_plans, :users, :stencils,

  # Shallow routes
  it 'allows indexing' do
    expect( :get => 'conversations' ).to route_to( controller: 'conversations', action: 'index' )
  end
  it 'allows showing' do
    expect( :get => 'conversations/1' ).to route_to( controller: 'conversations', action: 'show', id: '1' )
  end
#   it 'does not allow new' do
#     pending 'Needs analysis of how to block #show gloming on to "new".'
#     expect( :get => 'conversations/new' ).not_to be_routable
#   end
  it 'does not allow creating' do
    expect( :post => 'conversations' ).not_to be_routable
  end
  it 'does not allow editing' do
    expect( :get => 'conversations/1/edit' ).not_to be_routable
  end
  it 'does not allow updating' do
    expect( :put => 'conversations/1' ).not_to be_routable
  end
  it 'does not allow deleting' do
    expect( :delete => 'conversations/1' ).not_to be_routable
  end
  
  # Nested routes via stencil
  it 'allows listing via stencils' do
    expect( :get => 'stencils/1/conversations' ).to route_to(
      controller: 'conversations',
      action: 'index',
      stencil_id: '1'
    )
  end  

  it 'does not allow showing via stencils' do
    expect( :get => 'stencils/1/conversations/2' ).not_to be_routable
  end

  it 'allows creating via stencils' do
    expect( :post => 'stencils/1/conversations' ).to route_to(
      controller: 'conversations',
      action: 'create',
      stencil_id: '1'
    )
  end

  it 'does not allow updating via stencils' do
    expect( :put => 'stencils/1/conversations/2' ).not_to be_routable
  end

  it 'does not allow deleting via stencils' do
    expect( :delete => 'stencils/2/conversations/1' ).not_to be_routable
  end

  it 'allows forcing conversation status' do
    expect( :post=> 'stencils/1/conversations/2/force' ).to route_to(
      controller: 'conversations',
      action: 'force_status',
      stencil_id: '1',
      id: '2'
    )
  end

end
