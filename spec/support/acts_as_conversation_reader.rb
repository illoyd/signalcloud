shared_examples 'a conversation reader' do |conversation_count|
  it 'reads the file without errors' do
    expect{ subject.read }.not_to raise_error
  end
  
  it 'returns five conversations' do
    subject.read.count.should == conversation_count
  end
  
  it 'returns an array of conversations' do
    klasses = subject.read.map{ |cc| cc.class.name }.uniq
    klasses.should =~ ['Conversation']
  end
  
  it 'attaches the stencil to each conversation' do
    stencil_ids = subject.read.map{ |cc| cc.stencil_id }.uniq
    stencil_ids.should =~ [stencil.id]
  end
  
  it 'conversations are valid' do
    subject.read.each { |cc| cc.should be_valid }
  end
end