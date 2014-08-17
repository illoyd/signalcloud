require "rails_helper"

describe ApplicationHelper, :type => :helper do
  # render_views

  describe "#icon" do
    it "uses defaults" do
      output = helper.icon()
      expect(output).to include('icon-blank')
      expect(output).to include("style=''")
    end
    it "uses stencil symbol" do
      output = helper.icon( :stencils )
      expect(output).to include('icon-edit')
      expect(output).to include("style=''")
    end
    it "uses stencil string" do
      output = helper.icon( 'stencils' )
      expect(output).to include('icon-edit')
      expect(output).to include("style=''")
    end
    it "adds options" do
      output = helper.icon( :stencils, style: "font-size: bigger" )
      expect(output).to include('icon-edit')
      expect(output).to include("style='font-size: bigger'")
    end
  end
  
  describe '#humanize_phone_number' do

    context 'when US/CA number' do
      it 'renders full international' do
        expect(helper.humanize_phone_number('+12159009000')).to eq('+1 215 900 9000')        
      end
      it 'renders assumed international' do
        expect(helper.humanize_phone_number('12159009000')).to eq('+1 215 900 9000')        
      end
      it 'renders already formatted' do
        expect(helper.humanize_phone_number('+1 215 900 9000')).to eq('+1 215 900 9000')        
      end
      it 'renders strangely formatted' do
        expect(helper.humanize_phone_number('+12 15 90 090 00')).to eq('+1 215 900 9000')        
      end
      it 'renders strangely formatted 2' do
        expect(helper.humanize_phone_number('+ 1215 90 090 00')).to eq('+1 215 900 9000')        
      end
    end

    context 'when UK number' do
      it 'renders full international' do
        expect(helper.humanize_phone_number('+4475401861234')).to eq('+44 7540 1861234')
      end
      it 'renders assumed international' do
        expect(helper.humanize_phone_number('4475401861234')).to eq('+44 7540 1861234')
      end
      it 'renders already formatted' do
        expect(helper.humanize_phone_number('+44 7540 1861234')).to eq('+44 7540 1861234')
      end
      it 'renders strangely formatted 2' do
        expect(helper.humanize_phone_number('+ 4 475 40 18 6 1 2 3 4')).to eq('+44 7540 1861234')
      end
    end

  end

end
