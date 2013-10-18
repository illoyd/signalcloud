# encoding: UTF-8
require 'spec_helper'

describe Twilio::InboundSms do
  subject { Twilio::InboundSms.new SmsSid: 'Test', To: 'to', From: 'from', Body: 'body', SmsStatus: 'sent' }
  it_behaves_like 'a partner message'
end