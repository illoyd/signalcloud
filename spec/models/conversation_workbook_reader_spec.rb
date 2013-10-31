# encoding: UTF-8
require 'spec_helper'

describe ConversationWorkbookReader do
  let(:files) { File.join '.', 'spec', 'workbooks' }
  let(:stencil) { build_stubbed :stencil }
  let(:reader) { ConversationWorkbookReader.new( stencil, file ) }
  subject{ reader }
  
  describe '#book' do
    context 'with missing file path' do
      let(:file) { File.join files, 'ostriches.xlsx' }
      it 'raises File Not Found' do
        expect{ subject.book }.to raise_error(IOError)
      end
    end
    
    context 'with non-Excel document' do
      let(:file) { File.join files, 'test.txt' }
      it 'raises an error' do
        expect{ subject.book }.to raise_error
      end
    end
  end
  
  describe '#read' do
    context 'with a fully formed ExcelX workbook' do
      let(:file) { File.join files, 'complete.xlsx' }
      its(:book) { should be_a Roo::Base }
      it_behaves_like 'a conversation reader', 5
    end    

    context 'with a fully formed Excel workbook' do
      let(:file) { File.join files, 'complete.xls' }
      its(:book) { should be_a Roo::Base }
      it_behaves_like 'a conversation reader', 5
    end    

    context 'with a fully formed CSV workbook' do
      let(:file) { File.join files, 'complete.csv' }
      its(:book) { should be_a Roo::Base }
      it_behaves_like 'a conversation reader', 5
    end    

    context 'with parameters', :focus do
      let(:file) { File.join files, 'parameters.xlsx' }
      its(:book) { should be_a Roo::Base }
      it_behaves_like 'a conversation reader', 3

      context 'with the first conversation' do
        subject{ reader.read[0] }
        its(:parameters) { should have(3).params }
        its(:parameters) { should == { 'param1' => 'value1', 'param2' => 'value2', 'param3' => 'value3' }}
        its(:question)   { should == 'Q1 value1 value2 value3 test' }
      end

      context 'with the second conversation' do
        subject{ reader.read[1] }
        its(:parameters) { should have(1).param }
        its(:parameters) { should == { 'param2' => 'valueA' }}
        its(:question)   { should == 'Q2 valueA test' }
      end

      context 'with the third conversation' do
        subject{ reader.read[2] }
        its(:parameters) { should have(0).params }
        its(:parameters) { should == {} }
        its(:question)   { should == 'Q3 test' }
      end
    end    
  end
  
end