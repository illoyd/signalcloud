require 'spec_helper'
describe Twilio::InboundCallController do

  describe 'POST create' do
    fixtures :widgets
    
    it 'should request authorisation' do
      post :create
      expect( assigns(:widgets).to eq(Widget.all)
    end

    it 'should fail without proper authorisation' do
      pending 'todo'
      get :index
      expect( assigns(:widgets).to eq(Widget.all)
    end

    it 'should fail without proper authorisation' do
      pending 'todo'
      get :index
      expect( assigns(:widgets).to eq(Widget.all)
    end

    it 'should fail without proper authorisation' do
      pending 'todo'
      get :index
      expect( assigns(:widgets).to eq(Widget.all)
    end
    end
end

# additional
#.to render_template( *args )
#.to redirecto_to( destination )

# may also use
# render_views
