# encoding: UTF-8
require 'spec_helper'

describe Conversation, '#normalize_message', :type => :model do
  it 'should handle normal text' do
    expect(Conversation.normalize_message( 'abcd1234' )).to eq('abcd1234')
    expect(Conversation.normalize_message( 'ABCD1234' )).to eq('abcd1234')
    expect(Conversation.normalize_message( 'AbCd1234' )).to eq('abcd1234')
    expect(Conversation.normalize_message( 'aBcD 1234' )).to eq('abcd1234')
    expect(Conversation.normalize_message( 'Hello!' )).to eq('hello')
    expect(Conversation.normalize_message( 'Hello there, I love you!' )).to eq('hellothereiloveyou')
    expect(Conversation.normalize_message( '      Hello there, I love you!   ' )).to eq('hellothereiloveyou')
  end

  it 'should handle diacritics text' do
    expect(Conversation.normalize_message( "Café périferol" )).to eq('cafeperiferol')
    expect(Conversation.normalize_message( "Cafe periferôl" )).to eq('cafeperiferol')
    expect(Conversation.normalize_message( "Café périferôl" )).to eq('cafeperiferol')
  end

  it 'should handle japanese text' do
    expect(Conversation.normalize_message( "コンニチハ" )).to eq("konnitiha")
    expect(Conversation.normalize_message( "    コンニチハ    " )).to eq("konnitiha")
    expect(Conversation.normalize_message( " コ  ン ニ  チ  ハ " )).to eq("konnitiha")
    expect(Conversation.normalize_message( " コン ニチ ハ 4  22 31 33" )).to eq("konnitiha4223133")

    expect(Conversation.normalize_message( "こんにちは" )).to eq("konnitiha")
    expect(Conversation.normalize_message( "    こんにちは    " )).to eq("konnitiha")
    expect(Conversation.normalize_message( " こ ん           に ち は " )).to eq("konnitiha")
    expect(Conversation.normalize_message( " こ ん           に ち は 4  22 31 33" )).to eq("konnitiha4223133")
    
    expect(Conversation.normalize_message( "コンニチハ" )).to eq(Conversation.normalize_message( "こんにちは" ))
  end

  it 'should handle special punctuation text' do
    
  end
  
  it 'should handle currencies' do
    expect(Conversation.normalize_message( '$9.74' )).to eq('974')
    expect(Conversation.normalize_message( 'US$9.74' )).to eq('us974')
    expect(Conversation.normalize_message( '¥1,000,564' )).to eq('1000564')
    expect(Conversation.normalize_message( '€5,321,987.45' )).to eq('532198745')
    expect(Conversation.normalize_message( '€5.321.987,45' )).to eq('532198745')
    expect(Conversation.normalize_message( 'S/.1,345.65' )).to eq('s134565')
  end
end
