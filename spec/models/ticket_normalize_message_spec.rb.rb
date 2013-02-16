# encoding: UTF-8
require 'spec_helper'

describe Ticket, '#normalize_message' do
  it 'should handle normal text' do
    Ticket.normalize_message( 'abcd1234' ).should == 'abcd1234'
    Ticket.normalize_message( 'ABCD1234' ).should == 'abcd1234'
    Ticket.normalize_message( 'AbCd1234' ).should == 'abcd1234'
    Ticket.normalize_message( 'aBcD 1234' ).should == 'abcd1234'
    Ticket.normalize_message( 'Hello!' ).should == 'hello'
    Ticket.normalize_message( 'Hello there, I love you!' ).should == 'hellothereiloveyou'
    Ticket.normalize_message( '      Hello there, I love you!   ' ).should == 'hellothereiloveyou'
  end

  it 'should handle diacritics text' do
    Ticket.normalize_message( "Café périferol" ).should == 'cafeperiferol'
    Ticket.normalize_message( "Cafe periferôl" ).should == 'cafeperiferol'
    Ticket.normalize_message( "Café périferôl" ).should == 'cafeperiferol'
  end

  it 'should handle japanese text' do
    Ticket.normalize_message( "コンニチハ" ).should == "konnitiha"
    Ticket.normalize_message( "    コンニチハ    " ).should == "konnitiha"
    Ticket.normalize_message( " コ  ン ニ  チ  ハ " ).should == "konnitiha"
    Ticket.normalize_message( " コン ニチ ハ 4  22 31 33" ).should == "konnitiha4223133"

    Ticket.normalize_message( "こんにちは" ).should == "konnitiha"
    Ticket.normalize_message( "    こんにちは    " ).should == "konnitiha"
    Ticket.normalize_message( " こ ん           に ち は " ).should == "konnitiha"
    Ticket.normalize_message( " こ ん           に ち は 4  22 31 33" ).should == "konnitiha4223133"
    
    Ticket.normalize_message( "コンニチハ" ).should == Ticket.normalize_message( "こんにちは" )
  end

  it 'should handle special punctuation text' do
    
  end
  
  it 'should handle currencies' do
    Ticket.normalize_message( '$9.74' ).should == '974'
    Ticket.normalize_message( 'US$9.74' ).should == 'us974'
    Ticket.normalize_message( '¥1,000,564' ).should == '1000564'
    Ticket.normalize_message( '€5,321,987.45' ).should == '532198745'
    Ticket.normalize_message( '€5.321.987,45' ).should == '532198745'
    Ticket.normalize_message( 'S/.1,345.65' ).should == 's134565'
  end
end
