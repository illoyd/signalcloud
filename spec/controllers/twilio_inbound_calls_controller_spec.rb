require 'spec_helper'
describe Twilio::InboundCallsController do

  describe 'POST create' do
    #fixtures :widgets
    
    context 'when not authorised' do
      it 'responds with forbidden' do
        pending
        post :create
        response.status.should eq( :forbidden )
      end
    end
    
    context 'when authorised' do
      it 'responds with OK' do
        pending
      end
    end
  end
end

# additional
#.to render_template( *args )
#.to redirecto_to( destination )

# may also use
# render_views
