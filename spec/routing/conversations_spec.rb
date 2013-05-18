require 'spec_helper'

describe 'routing to conversations' do

  # Shallow routes
  it 'allows indexing' do
    expect( :get => 'organizations/1/conversations' ).to route_to( controller: 'conversations', action: 'index', organization_id: '1' )
  end
  it 'allows showing' do
    expect( :get => 'organizations/1/conversations/1' ).to route_to( controller: 'conversations', action: 'show', id: '1', organization_id: '1' )
  end
#   it 'does not allow new' do
#     pending 'Needs analysis of how to block #show gloming on to "new".'
#     expect( :get => 'conversations/new' ).not_to be_routable
#   end
  it 'does not allow creating' do
    expect( :post => 'organizations/1/conversations' ).not_to be_routable
  end
  it 'does not allow editing' do
    expect( :get => 'organizations/1/conversations/1/edit' ).not_to be_routable
  end
  it 'does not allow updating' do
    expect( :put => 'organizations/1/conversations/1' ).not_to be_routable
  end
  it 'does not allow deleting' do
    expect( :delete => 'organizations/1/conversations/1' ).not_to be_routable
  end
  
  # Nested routes via stencil
  it 'allows listing via stencils' do
    expect( :get => 'organizations/1/stencils/1/conversations' ).to route_to(
      controller: 'conversations',
      action: 'index',
      stencil_id: '1',
      organization_id: '1'
    )
  end  

  it 'does not allow showing via stencils' do
    expect( :get => 'organizations/1/stencils/1/conversations/2' ).not_to be_routable
  end

  it 'allows creating via stencils' do
    expect( :post => 'organizations/1/stencils/1/conversations' ).to route_to(
      controller: 'conversations',
      action: 'create',
      stencil_id: '1',
      organization_id: '1'
    )
  end

  it 'does not allow updating via stencils' do
    expect( :put => 'organizations/1/stencils/1/conversations/2' ).not_to be_routable
  end

  it 'does not allow deleting via stencils' do
    expect( :delete => 'organizations/1/stencils/2/conversations/1' ).not_to be_routable
  end

  it 'allows forcing conversation status' do
    expect( :post=> 'organizations/1/conversations/2/force' ).to route_to(
      controller: 'conversations',
      action: 'force_status',
      id: '2',
      organization_id: '1'
    )
  end

end
