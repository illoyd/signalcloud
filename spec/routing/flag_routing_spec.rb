require 'spec_helper'

describe 'routing to flag icons', :type => :routing do
  #fixtures :organizations, :account_plans, :users

#   it 'routes /organizations/:id to organizations#show for id' do
#     expect( :get => 'organizations/1' ).to route_to(
#       controller: 'organizations',
#       action: 'show',
#       id: '1'
#     )
#   end  

  ISO3166::Country::Names.each do |(name,alpha2)| alpha2
    ['medium'].each do |size|
      country = alpha2.to_s.downcase
      it "#{country.upcase} flag exists" do
        icon_url = './app/assets/images/flags/%s/%s.png' % [size, country]
        expect( File.exist? icon_url ).to be_truthy
      end
    end
  end

end
