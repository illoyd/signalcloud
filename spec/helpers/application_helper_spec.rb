require "spec_helper"

describe ApplicationHelper do
  # render_views

  describe "#icon" do
    it "uses defaults" do
      output = helper.icon()
      output.should include('icon-blank')
      output.should include("style=''")
    end
    it "uses stencil symbol" do
      output = helper.icon( :stencils )
      output.should include('icon-edit')
      output.should include("style=''")
    end
    it "uses stencil string" do
      output = helper.icon( 'stencils' )
      output.should include('icon-edit')
      output.should include("style=''")
    end
    it "adds options" do
      output = helper.icon( :stencils, style: "font-size: bigger" )
      output.should include('icon-edit')
      output.should include("style='font-size: bigger'")
    end
  end
  
  describe '#humanize_phone_number' do

    context 'when US/CA number' do
      it 'renders full international' do
        helper.humanize_phone_number('+12159009000').should == '+1 215 900 9000'        
      end
      it 'renders assumed international' do
        helper.humanize_phone_number('12159009000').should == '+1 215 900 9000'        
      end
      it 'renders already formatted' do
        helper.humanize_phone_number('+1 215 900 9000').should == '+1 215 900 9000'        
      end
      it 'renders strangely formatted' do
        helper.humanize_phone_number('+12 15 90 090 00').should == '+1 215 900 9000'        
      end
      it 'renders strangely formatted 2' do
        helper.humanize_phone_number('+ 1215 90 090 00').should == '+1 215 900 9000'        
      end
    end

    context 'when UK number' do
      it 'renders full international' do
        helper.humanize_phone_number('+4475401861234').should == '+44 7540 1861234'
      end
      it 'renders assumed international' do
        helper.humanize_phone_number('4475401861234').should == '+44 7540 1861234'
      end
      it 'renders already formatted' do
        helper.humanize_phone_number('+44 7540 1861234').should == '+44 7540 1861234'
      end
      it 'renders strangely formatted 2' do
        helper.humanize_phone_number('+ 4 475 40 18 6 1 2 3 4').should == '+44 7540 1861234'
      end
    end

  end

end
