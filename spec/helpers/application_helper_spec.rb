require "spec_helper"

describe ApplicationHelper, :type => :helper do
  # render_views

  describe "#icon" do
    context 'when blank' do
      let(:output) { helper.icon() }
      it 'uses blank icon' do
        expect(output).to include('fa-blank')
      end
      it 'does not include style attribute' do
        expect(output).not_to include('style')
      end
    end
    
    context 'when given symbol' do
      let(:output) { helper.icon(:my_stencil) }
      it 'uses icon' do
        expect(output).to include('fa-my-stencil')
      end
      it 'does not include style attribute' do
        expect(output).not_to include('style')
      end
    end
    
    context 'when given string' do
      let(:output) { helper.icon('my_stencil') }
      it 'uses icon' do
        expect(output).to include('fa-my-stencil')
      end
      it 'does not include style attribute' do
        expect(output).not_to include('style')
      end
    end
    
    context 'when given options' do
      let(:output) { helper.icon('my_stencil', style: 'font-size: bigger', ostriches: 'amazing') }
      it 'uses icon' do
        expect(output).to include('fa-my-stencil')
      end
      it 'includes style attribute' do
        expect(output).to include('style')
      end
      it 'includes style value' do
        expect(output).to include('font-size: bigger')
      end
      it 'includes ostriches attribute' do
        expect(output).to include('ostriches')
      end
      it 'includes ostriches value' do
        expect(output).to include('amazing')
      end
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
