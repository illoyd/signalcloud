shared_examples 'a costable item' do |factory|

  describe '#cost' do
    [ [nil,nil], [nil,1], [1,nil], [1,1], [1,-1], [-1,1], [0.25,-0.32] ].each do |costs|
      costs.map!{ |cost| cost.nil? ? nil : BigDecimal.new(cost.to_s) }
      it "properly sums provider:#{costs.first} and our:#{costs.second}" do
        msg = build factory, provider_cost: costs.first, our_cost: costs.second
        msg.cost.should == costs.reject{ |entry| entry.nil? }.sum
      end
    end
  end

  describe '#has_cost?' do
    context 'when both costs are present' do
      subject { build factory, provider_cost: -1.00, our_cost: -0.50 }
      its(:'has_cost?') { should be_true }
    end
    context 'when only provider_cost is present' do
      subject { build factory, provider_cost: -1.00, our_cost: nil }
      its(:'has_cost?') { should be_false }
    end
    context 'when only our_cost is present' do
      subject { build factory, provider_cost: nil, our_cost: -0.50 }
      its(:'has_cost?') { should be_false }
    end
    context 'when both costs are not present' do
      subject { build factory, provider_cost: nil, our_cost: nil }
      its(:'has_cost?') { should be_false }
    end
  end
  
  describe '#provider_cost=' do
    context 'when new cost is not nil' do
      let(:provider_cost) { -1.00 }
      subject { build factory }

      it 'updates provider_cost' do
        expect{ subject.provider_cost = provider_cost }.to change{ subject.provider_cost }.to(provider_cost)
      end
      it 'updates our_cost' do
        expect{ subject.provider_cost = provider_cost }.to change{ subject.our_cost }
      end
    end
    context 'when new cost is nil' do
      let(:provider_cost) { nil }
      subject { build factory, :with_costs }

      it 'updates provider_cost' do
        expect{ subject.provider_cost = provider_cost }.to change{ subject.provider_cost }.to(nil)
      end
      it 'updates our_cost' do
        expect{ subject.provider_cost = provider_cost }.to change{ subject.our_cost }.to(nil)
      end
    end
  end

end