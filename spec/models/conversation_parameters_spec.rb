# encoding: UTF-8
require 'spec_helper'

describe Conversation do

  [ :question, :expected_confirmed_answer, :expected_denied_answer, :confirmed_reply, :denied_reply, :failed_reply, :expired_reply ].each do |attribute|
    context "when #{attribute} is missing" do
      subject { build_stubbed :conversation, attribute => nil }
      
      describe "##{attribute}_template" do
        it 'returns a template' do
          subject.send( "#{attribute}_template".to_sym ).should be_a Liquid::Template
        end
        it 'provides a blank text' do
          subject.send( "#{attribute}_template".to_sym ).render.should be_blank
        end
      end
  
      describe '#defined_parameters' do
        it 'returns an empty array' do
          subject.defined_parameters.should be_empty
        end
      end
  
    end # missing attribute
    
    context "when #{attribute} is defined" do
      let(:text) { 'hello' }
      subject { build_stubbed :conversation, attribute => text }
      
      describe "##{attribute}_template" do
        it 'returns a template' do
          subject.send( "#{attribute}_template".to_sym ).should be_a Liquid::Template
        end
        it 'provides expected text' do
          subject.send( "#{attribute}_template".to_sym ).render.should == text
        end
      end
  
      describe '#defined_parameters' do
        it 'returns an empty array' do
          subject.defined_parameters.should be_empty
        end
      end
  
    end # defined attribute

    context "when #{attribute} has 1 parameter" do
      let(:text)       { 'hello {{name}}' }
      let(:parameters) { { 'name' => '{{name}}' } }
      let(:names)      { parameters.keys }
      subject { build_stubbed :conversation, attribute => text }
      
      describe "##{attribute}_template" do
        it 'returns a template' do
          subject.send( "#{attribute}_template".to_sym ).should be_a Liquid::Template
        end
        it 'provides expected text' do
          subject.send( "#{attribute}_template".to_sym ).render(parameters).should == text
        end
      end
  
      describe '#defined_parameters' do
        it 'has expected parameters' do
          subject.defined_parameters.should == names
        end
      end
  
    end # has 1 parameter

    context "when #{attribute} has 2 parameters" do
      let(:text)       { 'hello {{first_name}} {{last_name}}' }
      let(:parameters) { { 'first_name' => '{{first_name}}', 'last_name' => '{{last_name}}' } }
      let(:names)      { parameters.keys }
      subject { build_stubbed :conversation, attribute => text }
      
      describe "##{attribute}_template" do
        it 'returns a template' do
          subject.send( "#{attribute}_template".to_sym ).should be_a Liquid::Template
        end
        it 'provides expected text' do
          subject.send( "#{attribute}_template".to_sym ).render(parameters).should == text
        end
      end
  
      describe '#defined_parameters' do
        it 'has expected parameters' do
          subject.defined_parameters.should == names
        end
      end
  
    end # has 2 parameters
  end

end