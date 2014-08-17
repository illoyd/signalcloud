shared_examples 'a partner message' do

  [ :sid, :to, :from, :body, :created_at, :updated_at, :sent_at, :status, :direction, :price, :price_unit, :segments, :sent?, :sending?, :queued?, :received?, :failed?, :inbound?, :outbound? ].uniq.each do |attribute|
    it { is_expected.to respond_to(attribute).with(0).arguments }
  end
  
end
