require 'spec_helper'

describe PhoneBook do

  # Construct a book, attaching numbers for each country as well as defaults
  def create_book( defaults=0, us_numbers=0, ca_numbers=0, gb_numbers=0 )
    book = create(:phone_book)
    
    defaults.times do
      pn = create :phone_number, account: book.account
      book.phone_book_entries.create phone_number_id: pn.id, country: nil
    end
    
    us_numbers.times do
      pn = create :us_phone_number, account: book.account
      book.phone_book_entries.create phone_number_id: pn.id, country: PhoneBookEntry::US
    end
    
    ca_numbers.times do
      pn = create :ca_phone_number, account: book.account
      book.phone_book_entries.create phone_number_id: pn.id, country: PhoneBookEntry::CA
    end
    
    gb_numbers.times do
      pn = create :uk_phone_number, account: book.account
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
  let(:my_number) { '+6012345678' }
  let(:au_number) { '+61418123456' }
  let(:ru_number) { '+79111234567' }
  let(:hk_number) { '+85212345678' }
  
  describe '#country_for_number' do
    let(:book) { create(:phone_book) }
    it 'recognises United States' do
      book.country_for_number(us_number).should == PhoneBookEntry::US
    end
    it 'recognises Canadian' do
      book.country_for_number(ca_number).should == PhoneBookEntry::CA
    end
    it 'recognises United Kingdom' do
      book.country_for_number(gb_number).should == PhoneBookEntry::GB
    end
    it "does not recognise other countries" do
      { Trinidad: tt_number, Malaysia: my_number, Australia: au_number, Russia: ru_number, HongKong: hk_number }.each do |country,number|
        book.country_for_number(number).should == PhoneBookEntry::DEFAULT
      end
    end
  end
  
  describe '#default_phone_numbers' do
    subject { create_book(3, 2, 2, 2) }
    its(:default_phone_numbers) { should have(3).items }
    it 'includes only default phone numbers' do
      numbers = subject.phone_numbers.where( 'phone_book_entries.country' => nil ).pluck(:phone_number_id)
      subject.default_phone_numbers.pluck(:phone_number_id).should eq(numbers)
    end
    it 'does not include US phone numbers' do
      numbers = subject.phone_numbers_by_country(PhoneBookEntry::US).pluck(:phone_number_id)
      subject.default_phone_numbers.pluck(:phone_number_id).should_not eq(numbers)
    end
    it 'does not include UK phone numbers' do
      numbers = subject.phone_numbers_by_country(PhoneBookEntry::UK).pluck(:phone_number_id)
      subject.default_phone_numbers.pluck(:phone_number_id).should_not eq(numbers)
    end
    it 'does not include CA phone numbers' do
      numbers = subject.phone_numbers_by_country(PhoneBookEntry::CA).pluck(:phone_number_id)
      subject.default_phone_numbers.pluck(:phone_number_id).should_not eq(numbers)
    end
  end

  describe '#select_from_number' do
    let(:default_numbers) { book.phone_numbers_by_country(nil).pluck('phone_numbers.id') }
    let(:us_numbers)      { book.phone_numbers_by_country(PhoneBookEntry::US).pluck('phone_numbers.id') }
    let(:ca_numbers)      { book.phone_numbers_by_country(PhoneBookEntry::CA).pluck('phone_numbers.id') }
    let(:gb_numbers)      { book.phone_numbers_by_country(PhoneBookEntry::GB).pluck('phone_numbers.id') }

    context 'when using only default numbers' do
      let(:book) { create_book(2, 0, 0, 0) }

      it 'selects a default number for US number' do
        default_numbers.should include( book.select_from_number( us_number ).id )
      end
      
      it 'selects a default number for a Canadian number' do
        default_numbers.should include( book.select_from_number( ca_number ).id )
      end
      
      it 'selects a default number for a United Kingdom number' do
        default_numbers.should include( book.select_from_number( gb_number ).id )
      end
      
      it 'selects a default number for a Trinidad number' do
        default_numbers.should include( book.select_from_number( tt_number ).id )
      end
      
      it 'selects a default number for a Malaysian number' do
        default_numbers.should include( book.select_from_number( my_number ).id )
      end
      
      it 'selects a default number for a Hong Kong number' do
        default_numbers.should include( book.select_from_number( hk_number ).id )
      end
      
      it 'selects a default number for a Australian number' do
        default_numbers.should include( book.select_from_number( au_number ).id )
      end
      
      it 'selects a default number for a Russian number' do
        default_numbers.should include( book.select_from_number( ru_number ).id )
      end
    end

    context 'when using only US numbers' do
      let(:book) { create_book(0, 2, 0, 0) }

      it 'selects a US number for US number' do
        us_numbers.should include( book.select_from_number( us_number ).id )
      end
      
      it 'selects a US number for a Canadian number' do
        us_numbers.should include( book.select_from_number( ca_number ).id )
      end
      
      it 'selects a US number for a United Kingdom number' do
        us_numbers.should include( book.select_from_number( gb_number ).id )
      end
      
      it 'selects a US number for a Trinidad number' do
        us_numbers.should include( book.select_from_number( tt_number ).id )
      end
      
      it 'selects a US number for a Malaysian number' do
        us_numbers.should include( book.select_from_number( my_number ).id )
      end
      
      it 'selects a US number for a Hong Kong number' do
        us_numbers.should include( book.select_from_number( hk_number ).id )
      end
      
      it 'selects a US number for a Australian number' do
        us_numbers.should include( book.select_from_number( au_number ).id )
      end
      
      it 'selects a US number for a Russian number' do
        us_numbers.should include( book.select_from_number( ru_number ).id )
      end
    end

    context 'when using only CA numbers' do
      let(:book) { create_book(0, 0, 2, 0) }

      it 'selects a CA number for US number' do
        ca_numbers.should include( book.select_from_number( us_number ).id )
      end
      
      it 'selects a CA number for a Canadian number' do
        ca_numbers.should include( book.select_from_number( ca_number ).id )
      end
      
      it 'selects a CA number for a United Kingdom number' do
        ca_numbers.should include( book.select_from_number( gb_number ).id )
      end
      
      it 'selects a CA number for a Trinidad number' do
        ca_numbers.should include( book.select_from_number( tt_number ).id )
      end
      
      it 'selects a CA number for a Malaysian number' do
        ca_numbers.should include( book.select_from_number( my_number ).id )
      end
      
      it 'selects a CA number for a Hong Kong number' do
        ca_numbers.should include( book.select_from_number( hk_number ).id )
      end
      
      it 'selects a CA number for a Australian number' do
        ca_numbers.should include( book.select_from_number( au_number ).id )
      end
      
      it 'selects a CA number for a Russian number' do
        ca_numbers.should include( book.select_from_number( ru_number ).id )
      end
    end

    context 'when using only UK numbers' do
      let(:book) { create_book(0, 0, 0, 2) }

      it 'selects a UK number for US number' do
        gb_numbers.should include( book.select_from_number( us_number ).id )
      end
      
      it 'selects a UK number for a Canadian number' do
        gb_numbers.should include( book.select_from_number( ca_number ).id )
      end
      
      it 'selects a UK number for a United Kingdom number' do
        gb_numbers.should include( book.select_from_number( gb_number ).id )
      end
      
      it 'selects a UK number for a Trinidad number' do
        gb_numbers.should include( book.select_from_number( tt_number ).id )
      end
      
      it 'selects a UK number for a Malaysian number' do
        gb_numbers.should include( book.select_from_number( my_number ).id )
      end
      
      it 'selects a UK number for a Hong Kong number' do
        gb_numbers.should include( book.select_from_number( hk_number ).id )
      end
      
      it 'selects a UK number for a Australian number' do
        gb_numbers.should include( book.select_from_number( au_number ).id )
      end
      
      it 'selects a UK number for a Russian number' do
        gb_numbers.should include( book.select_from_number( ru_number ).id )
      end
    end

    context 'when using all numbers' do
      let(:book) { create_book(2, 2, 2, 2) }

      it 'selects a US number for US number' do
        us_numbers.should include( book.select_from_number( us_number ).id )
      end
      
      it 'selects a CA number for a Canadian number' do
        ca_numbers.should include( book.select_from_number( ca_number ).id )
      end
      
      it 'selects a UK number for a United Kingdom number' do
        gb_numbers.should include( book.select_from_number( gb_number ).id )
      end
      
      it 'selects a default number for a Trinidad number' do
        default_numbers.should include( book.select_from_number( tt_number ).id )
      end
      
      it 'selects a default number for a Malaysian number' do
        default_numbers.should include( book.select_from_number( my_number ).id )
      end
      
      it 'selects a default number for a Hong Kong number' do
        default_numbers.should include( book.select_from_number( hk_number ).id )
      end
      
      it 'selects a default number for a Australian number' do
        default_numbers.should include( book.select_from_number( au_number ).id )
      end
      
      it 'selects a default number for a Russian number' do
        default_numbers.should include( book.select_from_number( ru_number ).id )
      end
    end

  end

end
