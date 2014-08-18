# encoding: UTF-8
require 'spec_helper'

describe MockCommunicationGateway, :type => :model do

  describe MockCommunicationGateway::MockMessage do
    subject { MockCommunicationGateway::MockMessage.new sid: 'Test', to: 'to', from: 'from', body: 'body', status: Message::SENT_SZ, direction: Message::OUT }
    it_behaves_like 'a partner message'
  end

end
