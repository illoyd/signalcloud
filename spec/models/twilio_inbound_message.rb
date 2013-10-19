# encoding: UTF-8
require 'spec_helper'

describe Twilio::InboundMessage do
  subject { Twilio::InboundMessage.new SmsSid: 'Test', To: 'to', From: 'from', Body: 'body', SmsStatus: 'sent' }
  it_behaves_like 'a partner message'
end