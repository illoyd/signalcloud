require 'spec_helper'

describe Account do
  before { VCR.insert_cassette 'accounts', record: :new_episodes }
  after { VCR.eject_cassette }
  #fixtures :accounts, :users
  subject { create(:account) }

  describe '#create_freshbooks_client' do
  
    context 'when not already configured' do
    
      it 'creates a freshbooks client' do
        expect{ subject.create_freshbooks_client }.to_not raise_error
      end
    
    end
  
  end

end
