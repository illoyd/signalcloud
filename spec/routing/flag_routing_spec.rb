require 'spec_helper'

describe 'routing to flag icons' do
  #fixtures :organizations, :account_plans, :users

#   it 'routes /organizations/:id to organizations#show for id' do
#     expect( :get => 'organizations/1' ).to route_to(
#       controller: 'organizations',
#       action: 'show',
#       id: '1'
#     )
#   end  

  ISO3166::Country::Names.each do |(name,alpha2)| alpha2
    country = alpha2.to_s.downcase
    it "#{country.upcase} flag exists" do
      size = 'medium'
      icon_url = './assets/images/flags/%s/%s.png' % [size.downcase, country.downcase]
      # expect( get: icon_url ).to be_routable
      expect{ File.exist? icon_url }.to be_true
    end
  end

end
