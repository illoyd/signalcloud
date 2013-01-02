# require 'spec_helper'
# describe 'events/index' do
#   it 'renders _event partial for each event' do
#     assign(:events, [stub_model(Event), stub_model(Event)] )
#     render
#     expect(view).to render_template(:partial=>'_event', :count=>2)
#   end  
# end
# 
# describe 'events/show' do
#   it 'displays the event location' do
#     assign(:event, stub_model(Event, location: 'Chicago'))
#     render
#     expect(rendered).to include('Chicago')
# end

# to force a controller
# controller.controller_path = 'events'
# controller.request.path_parameters[:controller] = 'events'

# to use a layout
# render :template => 'events/show', :layout => 'layouts/application'
