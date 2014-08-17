require 'spec_helper'

# Specs in this file have access to a helper object that includes
# the InvoicesHelper. For example:
#
# describe InvoicesHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end

RSpec.describe InvoicesHelper, :type => :helper do

  describe '#status_tag_for' do
    context 'with new status' do
      let(:invoice) { Invoice.new( workflow_state: 'new' ) }
      it 'returns a label snippet for new status' do
        expect( helper.status_tag_for(invoice) ).to eq("<span class=\"label label-new\">new</span>")
      end
    end

    context 'with prepared status' do
      let(:invoice) { Invoice.new( workflow_state: 'prepared' ) }
      it 'returns a label snippet for prepared status' do
        expect( helper.status_tag_for(invoice) ).to eq("<span class=\"label label-prepared\">prepared</span>")
      end
    end

    context 'with settled status' do
      let(:invoice) { Invoice.new( workflow_state: 'settled' ) }
      it 'returns a label snippet for settled status' do
        expect( helper.status_tag_for(invoice) ).to eq("<span class=\"label label-settled\">settled</span>")
      end
    end
  end

end
