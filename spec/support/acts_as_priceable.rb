shared_examples 'a priceable item' do |factory|

  describe '#price' do
    [ [nil,nil], [nil,1], [1,nil], [1,1], [1,-1], [-1,1], [0.25,-0.32] ].each do |prices|
      prices.map!{ |price| price.nil? ? nil : BigDecimal.new(price.to_s) }
      it "properly sums provider:#{prices.first} and our:#{prices.second}" do
        msg = build factory, provider_price: prices.first, our_price: prices.second
        msg.price.should == prices.reject{ |entry| entry.nil? }.sum
      end
    end
  end

  describe '#has_price?' do
    context 'when both prices are present' do
      subject { build factory, provider_price: -1.00, our_price: -0.50 }
      its(:'has_price?') { should be_true }
    end
    context 'when only provider_price is present' do
      subject { build factory, provider_price: -1.00, our_price: nil }
      its(:'has_price?') { should be_false }
    end
    context 'when only our_price is present' do
      subject { build factory, provider_price: nil, our_price: -0.50 }
      its(:'has_price?') { should be_false }
    end
    context 'when both prices are not present' do
      subject { build factory, provider_price: nil, our_price: nil }
      its(:'has_price?') { should be_false }
    end
  end
  
  describe '#provider_price=' do
    context 'when new price is not nil' do
      let(:provider_price) { -1.00 }
      subject { build factory }

      it 'updates provider_price' do
        expect{ subject.provider_price = provider_price }.to change{ subject.provider_price }.to(provider_price)
      end
      it 'updates our_price' do
        expect{ subject.provider_price = provider_price }.to change{ subject.our_price }
      end
    end
    context 'when new price is nil' do
      let(:provider_price) { nil }
      subject { build factory, :with_prices }

      it 'updates provider_price' do
        expect{ subject.provider_price = provider_price }.to change{ subject.provider_price }.to(nil)
      end
      it 'updates our_price' do
        expect{ subject.provider_price = provider_price }.to change{ subject.our_price }.to(nil)
      end
    end
  end

end