require 'rails_helper'

describe ApplicationPolicy do

  context 'as a visitor' do
    it 'raises error on creation' do
      expect{ described_class.new(nil, Object.new) }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

end
