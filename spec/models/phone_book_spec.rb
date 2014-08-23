require 'spec_helper'

describe PhoneBook, :type => :model do

  # Construct a book, attaching numbers for each country as well as defaults
  def create_book( defaults=0, us_numbers=0, ca_numbers=0, gb_numbers=0 )
    organization = create :organization, :test_twilio
    comm_gateway = organization.communication_gateways.first
    book = create(:phone_book, organization: organization)
    
    defaults.times do |n|
      pn = create :phone_number, organization: book.organization, communication_gateway: comm_gateway
      book.phone_book_entries.create phone_number_id: pn.id, country: nil
    end
    
    us_numbers.times do
      pn = create :us_phone_number, organization: book.organization, communication_gateway: comm_gateway
      book.phone_book_entries.create phone_number_id: pn.id, country: PhoneBookEntry::US
    end
    
    ca_numbers.times do
      pn = create :ca_phone_number, organization: book.organization, communication_gateway: comm_gateway
      book.phone_book_entries.create phone_number_id: pn.id, country: PhoneBookEntry::CA
    end
    
    gb_numbers.times do
      pn = create :uk_phone_number, organization: book.organization, communication_gateway: comm_gateway
      book.phone_book_entries.create phone_number_id: pn.id, country: PhoneBookEntry::GB
    end
    
    book.reload
    book.phone_book_entries(true)
    return book
  end
  
  let(:us_number) { '+12151234567' }
  let(:gb_number) { '+447540123456' }
  let(:ca_number) { '+14161234567' }
  let(:tt_number) { '+18681234567' }
  let(:my_number) { '+60123959999' }
  let(:au_number) { '+61418123456' }
  let(:ru_number) { '+79111234567' }
  let(:hk_number) { '+85212345678' }
  
  describe '#default_phone_numbers' do
    subject { create_book(3, 2, 2, 2) }

    describe '#default_phone_numbers' do
      subject { super().default_phone_numbers }

      it 'has 3 items' do
        expect(subject.size).to eq(3)
      end
    end
    it 'includes only default phone numbers' do
      numbers = subject.phone_book_entries.where( country: nil ).pluck(:phone_number_id)
      expect(subject.default_phone_numbers.pluck(:id)).to eq(numbers)
    end
    it 'does not include US phone numbers' do
      numbers = subject.phone_numbers_by_country(PhoneBookEntry::US)
      expect(subject.default_phone_numbers).not_to eq(numbers)
    end
    it 'does not include UK phone numbers' do
      numbers = subject.phone_numbers_by_country(PhoneBookEntry::UK)
      expect(subject.default_phone_numbers).not_to eq(numbers)
    end
    it 'does not include CA phone numbers' do
      numbers = subject.phone_numbers_by_country(PhoneBookEntry::CA)
      expect(subject.default_phone_numbers).not_to eq(numbers)
    end
  end

  describe '#select_internal_number_for' do
    let(:default_numbers) { book.default_phone_numbers }
    let(:us_numbers)      { book.phone_numbers_by_country(PhoneBookEntry::US) }
    let(:ca_numbers)      { book.phone_numbers_by_country(PhoneBookEntry::CA) }
    let(:gb_numbers)      { book.phone_numbers_by_country(PhoneBookEntry::GB) }

    context 'when using only default numbers' do
      let(:book) { create_book(2, 0, 0, 0) }

      it 'selects a default number for US number' do
        expect(default_numbers).to include( book.select_internal_number_for( us_number ) )
      end
      
      it 'selects a default number for a Canadian number' do
        expect(default_numbers).to include( book.select_internal_number_for( ca_number ) )
      end
      
      it 'selects a default number for a United Kingdom number' do
        expect(default_numbers).to include( book.select_internal_number_for( gb_number ) )
      end
      
      it 'selects a default number for a Trinidad number' do
        expect(default_numbers).to include( book.select_internal_number_for( tt_number ) )
      end
      
      it 'selects a default number for a Malaysian number' do
        expect(default_numbers).to include( book.select_internal_number_for( my_number ) )
      end
      
      it 'selects a default number for a Hong Kong number' do
        expect(default_numbers).to include( book.select_internal_number_for( hk_number ) )
      end
      
      it 'selects a default number for a Australian number' do
        expect(default_numbers).to include( book.select_internal_number_for( au_number ) )
      end
      
      it 'selects a default number for a Russian number' do
        expect(default_numbers).to include( book.select_internal_number_for( ru_number ) )
      end
    end

    context 'when using only US numbers' do
      let(:book) { create_book(0, 2, 0, 0) }

      it 'selects a US number for US number' do
        expect(us_numbers).to include( book.select_internal_number_for( us_number ) )
      end
      
      it 'selects a US number for a Canadian number' do
        expect(us_numbers).to include( book.select_internal_number_for( ca_number ) )
      end
      
      it 'selects a US number for a United Kingdom number' do
        expect(us_numbers).to include( book.select_internal_number_for( gb_number ) )
      end
      
      it 'selects a US number for a Trinidad number' do
        expect(us_numbers).to include( book.select_internal_number_for( tt_number ) )
      end
      
      it 'selects a US number for a Malaysian number' do
        expect(us_numbers).to include( book.select_internal_number_for( my_number ) )
      end
      
      it 'selects a US number for a Hong Kong number' do
        expect(us_numbers).to include( book.select_internal_number_for( hk_number ) )
      end
      
      it 'selects a US number for a Australian number' do
        expect(us_numbers).to include( book.select_internal_number_for( au_number ) )
      end
      
      it 'selects a US number for a Russian number' do
        expect(us_numbers).to include( book.select_internal_number_for( ru_number ) )
      end
    end

    context 'when using only CA numbers' do
      let(:book) { create_book(0, 0, 2, 0) }

      it 'selects a CA number for US number' do
        expect(ca_numbers).to include( book.select_internal_number_for( us_number ) )
      end
      
      it 'selects a CA number for a Canadian number' do
        expect(ca_numbers).to include( book.select_internal_number_for( ca_number ) )
      end
      
      it 'selects a CA number for a United Kingdom number' do
        expect(ca_numbers).to include( book.select_internal_number_for( gb_number ) )
      end
      
      it 'selects a CA number for a Trinidad number' do
        expect(ca_numbers).to include( book.select_internal_number_for( tt_number ) )
      end
      
      it 'selects a CA number for a Malaysian number' do
        expect(ca_numbers).to include( book.select_internal_number_for( my_number ) )
      end
      
      it 'selects a CA number for a Hong Kong number' do
        expect(ca_numbers).to include( book.select_internal_number_for( hk_number ) )
      end
      
      it 'selects a CA number for a Australian number' do
        expect(ca_numbers).to include( book.select_internal_number_for( au_number ) )
      end
      
      it 'selects a CA number for a Russian number' do
        expect(ca_numbers).to include( book.select_internal_number_for( ru_number ) )
      end
    end

    context 'when using only UK numbers' do
      let(:book) { create_book(0, 0, 0, 2) }

      it 'selects a UK number for US number' do
        expect(gb_numbers).to include( book.select_internal_number_for( us_number ) )
      end
      
      it 'selects a UK number for a Canadian number' do
        expect(gb_numbers).to include( book.select_internal_number_for( ca_number ) )
      end
      
      it 'selects a UK number for a United Kingdom number' do
        expect(gb_numbers).to include( book.select_internal_number_for( gb_number ) )
      end
      
      it 'selects a UK number for a Trinidad number' do
        expect(gb_numbers).to include( book.select_internal_number_for( tt_number ) )
      end
      
      it 'selects a UK number for a Malaysian number' do
        expect(gb_numbers).to include( book.select_internal_number_for( my_number ) )
      end
      
      it 'selects a UK number for a Hong Kong number' do
        expect(gb_numbers).to include( book.select_internal_number_for( hk_number ) )
      end
      
      it 'selects a UK number for a Australian number' do
        expect(gb_numbers).to include( book.select_internal_number_for( au_number ) )
      end
      
      it 'selects a UK number for a Russian number' do
        expect(gb_numbers).to include( book.select_internal_number_for( ru_number ) )
      end
    end

    context 'when using all numbers' do
      let(:book) { create_book(2, 2, 2, 2) }

      it 'selects a US number for US number' do
        expect(us_numbers).to include( book.select_internal_number_for( us_number ) )
      end
      
      it 'selects a CA number for a Canadian number' do
        expect(ca_numbers).to include( book.select_internal_number_for( ca_number ) )
      end
      
      it 'selects a UK number for a United Kingdom number' do
        expect(gb_numbers).to include( book.select_internal_number_for( gb_number ) )
      end
      
      it 'selects a default number for a Trinidad number' do
        expect(default_numbers).to include( book.select_internal_number_for( tt_number ) )
      end
      
      it 'selects a default number for a Malaysian number' do
        expect(default_numbers).to include( book.select_internal_number_for( my_number ) )
      end
      
      it 'selects a default number for a Hong Kong number' do
        expect(default_numbers).to include( book.select_internal_number_for( hk_number ) )
      end
      
      it 'selects a default number for a Australian number' do
        expect(default_numbers).to include( book.select_internal_number_for( au_number ) )
      end
      
      it 'selects a default number for a Russian number' do
        expect(default_numbers).to include( book.select_internal_number_for( ru_number ) )
      end
    end

  end

end
