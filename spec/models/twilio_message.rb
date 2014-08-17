# encoding: UTF-8
require 'spec_helper'

describe Twilio::REST::Message::Smash, :type => :model do
  subject { Twilio::REST::Message::Smash.new sid: 'Test', to: 'to', from: 'from', body: 'body', status: 'sent', direction: 'outbound-api' }
  it_behaves_like 'a partner message'
end