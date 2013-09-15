# encoding: UTF-8
require 'spec_helper'

describe Conversation, '#normalize_message' do
  it 'should handle normal text' do
    Conversation.normalize_message( 'abcd1234' ).should == 'abcd1234'
    Conversation.normalize_message( 'ABCD1234' ).should == 'abcd1234'
    Conversation.normalize_message( 'AbCd1234' ).should == 'abcd1234'
    Conversation.normalize_message( 'aBcD 1234' ).should == 'abcd1234'
    Conversation.normalize_message( 'Hello!' ).should == 'hello'
    Conversation.normalize_message( 'Hello there, I love you!' ).should == 'hellothereiloveyou'
    Conversation.normalize_message( '      Hello there, I love you!   ' ).should == 'hellothereiloveyou'
  end

  it 'should handle diacritics text' do
    Conversation.normalize_message( "Café périferol" ).should == 'cafeperiferol'
    Conversation.normalize_message( "Cafe periferôl" ).should == 'cafeperiferol'
    Conversation.normalize_message( "Café périferôl" ).should == 'cafeperiferol'
  end

  it 'should handle japanese text' do
    Conversation.normalize_message( "コンニチハ" ).should == "konnitiha"
    Conversation.normalize_message( "    コンニチハ    " ).should == "konnitiha"
    Conversation.normalize_message( " コ  ン ニ  チ  ハ " ).should == "konnitiha"
    Conversation.normalize_message( " コン ニチ ハ 4  22 31 33" ).should == "konnitiha4223133"

    Conversation.normalize_message( "こんにちは" ).should == "konnitiha"
    Conversation.normalize_message( "    こんにちは    " ).should == "konnitiha"
    Conversation.normalize_message( " こ ん           に ち は " ).should == "konnitiha"
    Conversation.normalize_message( " こ ん           に ち は 4  22 31 33" ).should == "konnitiha4223133"
    
    Conversation.normalize_message( "コンニチハ" ).should == Conversation.normalize_message( "こんにちは" )
  end

  it 'should handle special punctuation text' do
    
  end
  
  it 'should handle currencies' do
    Conversation.normalize_message( '$9.74' ).should == '974'
    Conversation.normalize_message( 'US$9.74' ).should == 'us974'
    Conversation.normalize_message( '¥1,000,564' ).should == '1000564'
    Conversation.normalize_message( '€5,321,987.45' ).should == '532198745'
    Conversation.normalize_message( '€5.321.987,45' ).should == '532198745'
    Conversation.normalize_message( 'S/.1,345.65' ).should == 's134565'
  end
end
