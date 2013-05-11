require 'spec_helper'

describe PhoneBookEntry do

  it { should belong_to :phone_book }
  it { should belong_to :phone_number }

  [ :phone_book, :phone_number ].each do |attribute|
    it { should validate_presence_of attribute }
  end
  
  [ :country, :phone_number_id, :phone_book_id ].each do |attribute|
    it { should allow_mass_assignment_of attribute }
  end
  
  it { should ensure_inclusion_of(:country).in_array(PhoneBookEntry::COUNTRIES) }
  
  describe '#standardise_country' do
    let(:valid_country) { 'Malaysia' }
    let(:valid_alpha2) { 'MY' }
    let(:valid_alpha3) { 'MYS' }

    let(:invalid_country) { 'The Moon' }
    let(:invalid_alpha2) { 'MO' }
    let(:invalid_alpha3) { 'MOO' }
    
    it "accepts valid country alpha2" do
      subject.country = valid_alpha2
      expect { subject.standardise_country }.not_to change(subject, :country)
    end

    it "updates valid country name" do
      subject.country = valid_country
      expect { subject.standardise_country }.to change(subject, :country).to(valid_alpha2)
    end

    it "updates valid country alph3" do
      subject.country = valid_alpha3
      expect { subject.standardise_country }.to change(subject, :country).to(valid_alpha2)
    end

    it "updates valid lowercase country name" do
      subject.country = valid_country.downcase
      expect { subject.standardise_country }.to change(subject, :country).to(valid_alpha2)
    end

    it "updates valid uppercase country name" do
      subject.country = valid_country.upcase
      expect { subject.standardise_country }.to change(subject, :country).to(valid_alpha2)
    end

    it "updates valid lowercase country alph3" do
      subject.country = valid_alpha3.downcase
      expect { subject.standardise_country }.to change(subject, :country).to(valid_alpha2)
    end

    it "updates valid lowercase country alph2" do
      subject.country = valid_alpha2.downcase
      expect { subject.standardise_country }.to change(subject, :country).to(valid_alpha2)
    end

    it "ignores invalid country name" do
      subject.country = invalid_country
      expect { subject.standardise_country }.not_to change(subject, :country)
    end

    it "ignores invalid country alpha2" do
      subject.country = invalid_alpha2
      expect { subject.standardise_country }.not_to change(subject, :country)
    end

    it "ignores invalid country alpha3" do
      subject.country = invalid_alpha3
      expect { subject.standardise_country }.not_to change(subject, :country)
    end

    it 'ignores nil country name' do
      subject.country = nil
      expect { subject.standardise_country }.not_to change(subject, :country)
    end

    it 'converts blank country name to nil' do
      subject.country = ''
      expect { subject.standardise_country }.to change(subject, :country).to(nil)
    end

  end

end
