# encoding: UTF-8
require 'spec_helper'

describe ConversationWorkbookReader do
  let(:files) { File.join '.', 'spec', 'workbooks' }
  let(:stencil) { build_stubbed :stencil }
  subject{ ConversationWorkbookReader.new( stencil, file ) }
  
  describe '#book', :focus do
    context 'with valid XLSX document' do
      let(:file) { File.join files, 'complete.xlsx' }
      its(:book) { should be_a Spreadsheet::Workbook }
    end

    context 'with valid XLS document' do
      let(:file) { File.join files, 'complete.xls' }
      its(:book) { should be_a Spreadsheet::Workbook }
    end
    
    context 'with missing file path' do
      let(:file) { File.join files, 'ostriches.xlsx' }
      it 'raises File Not Found' do
        expect{ subject.book }.to raise_error(Errno::ENOENT)
      end
    end
    
    context 'with non-Excel document' do
      let(:file) { File.join files, 'test.txt' }
      it 'raises an error' do
        expect{ subject.book }.to raise_error
      end
    end
  end
    
  context 'with a fully formed Excel workbook' do
    let(:file)    { File.join files, 'complete.xlsx' }
    let(:expected_headers ) { [ :internal_number, :customer_number, :question, :expected_confirmed_answer, :confirmed_reply, :expected_denied_answer, :denied_reply, :seconds_to_live, :expired_reply, :failed_reply, :webhook_uri, :parameters ] }
    let(:expected_keys)     { h = HashWithIndifferentAccess.new; expected_headers.each_with_index{ |header,index| h[header] = index }; h }
    
    describe '#read' do
      it 'reads the file without errors' do
        expect{ subject.read }.not_to raise_error
      end
      
      it 'finds headers' do
        expect{ subject.read }.to change(subject, :headers).to(expected_headers)
      end
      
      it 'finds keys' do
        expect{ subject.read }.to change(subject, :keys).to(expected_keys)
      end
      
      it 'returns an array of conversations' do
      end
      
      it 'attaches the stencil to each conversation' do
      end
    end
    
    describe '#column' do
      before{ subject.read }
      it 'returns the expected column for each request' do
        expected_headers.each_with_index { |header,column| subject.send(:column, header).should == column }
      end
    end
    
    describe '#header' do
      before{ subject.read }
      it 'returns the expected header for each request' do
        expected_keys.each { |header,column| subject.send(:header, column).should == header }
      end
    end
    
  end
  
end