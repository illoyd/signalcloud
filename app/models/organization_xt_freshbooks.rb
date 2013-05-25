class Organization < ActiveRecord::Base

  ##
  # Get the current client's FreshBook organization, using the FreshBook global module.
  # In FreshBooks parlance, this is a 'Client' object.
  def freshbooks_client
    raise SignalCloud::MissingFreshBooksClientError.new(self) if self.freshbooks_id.blank?
    response = FreshBooks.account.client.get(client_id: self.freshbooks_id)
    raise SignalCloud::FreshBooksError.new( 'API Error: %s (%i)' % [response['error'], response['code']], response['code'] ) unless response.success?
    response['client']
  end
  
  ##
  # Helper method to create or update as necessary
  def create_or_update_freshbooks_client!
    self.freshbooks_id.nil? ? self.create_freshbooks_client! : self.update_freshbooks_client!
  end
  
  ##
  # Create a new FreshBooks client for this organization. This method will throw an error if a FreshBooks client already exists.
  def create_freshbooks_client!
    raise SignalCloud::FreshBooksClientAlreadyExistsError.new(self) unless self.freshbooks_id.nil?
    raise SignalCloud::FreshBooksError.new( 'Missing a primary contact.' ) if self.contact_address.nil?
    
    # Instruct FreshBooks API to create the organization, then save the resulting ID
    response = FreshBooks.account.client.create(self.assemble_freshbooks_client_data)
    
    # If this is a duplicate, try to find and re-use the account based on the email
    response = self.find_freshbooks_client_by_email if response.fetch('code', 0) == 40068.to_s
    
    # Otherwise, raise error
    raise SignalCloud::FreshBooksError.new( 'API Error: %s (%i)' % [response['error'], response['code']], response['code'] ) unless response.success?
    
    # Finally, save!
    self.freshbooks_id = response['client_id']
    self.save!
  end
  
  def update_freshbooks_client!
    raise SignalCloud::MissingFreshBooksClientError.new(self) if self.freshbooks_id.nil?
    raise SignalCloud::FreshBooksError.new( 'Missing a primary contact.' ) if self.contact_address.nil?

    # Instruct FreshBooks API to update the organization, then save the resulting ID
    response = FreshBooks.account.client.update(self.assemble_freshbooks_client_data.merge( client_id: self.freshbooks_id) )
    raise SignalCloud::FreshBooksError.new( 'API Error: %s (%i)' % [response['error'], response['code']], response['code'] ) unless response.success?
    self.save!
  end
  
  def find_freshbooks_client_by_email
    raise SignalCloud::FreshBooksError.new( 'Missing a primary contact.' ) if self.contact_address.nil?
    
    response = FreshBooks.account.client.list({ email: self.contact_address.email })
    raise SignalCloud::FreshBooksError.new( 'API Error: %s (%i)' % [response['error'], response['code']], response['code'] ) unless response.success?
    return response['clients']['client']
  end
  
  def assemble_freshbooks_client_data
    # Construct the complete client dataset to be passed to FreshBooks
    client_data = {
      organization: self.label,
      currency_code: FreshBooks::DEFAULT_CURRENCY
    }
    
    # Insert primary address if appropriate
    unless self.contact_address.nil?
      client_data.merge!({
        # Add primary contact
        first_name: self.contact_address.first_name,
        last_name:  self.contact_address.last_name,
        username:   self.contact_address.email,
        email:      self.contact_address.email,
        work_phone: self.contact_address.work_phone,

        # Add address
        p_street1:  self.contact_address.line1,
        p_street2:  self.contact_address.line2,
        p_city:     self.contact_address.city,
        p_state:    self.contact_address.region,
        p_country:  self.contact_address.country,
        p_code:     self.contact_address.postcode
      })
    end
    
    # Insert secondary address if appropriate
    unless self.billing_address.nil?
      client_data.merge!({
        s_street1:  self.billing_address.line1,
        s_street2:  self.billing_address.line2,
        s_city:     self.billing_address.city,
        s_state:    self.billing_address.region,
        s_country:  self.billing_address.country,
        s_code:     self.billing_address.postcode
      })
    end
    
    # Insert VAT data if appropriate
    client_data[:vat_name] unless self.vat_name.blank?
    client_data[:vat_number] unless self.vat_number.blank?
    { client: client_data }
  end
  
  def build_next_invoice( to_date=nil )
    to_date ||= DateTime.yesterday.end_of_day
    return self.invoices.build date_to: to_date
  end
  
  def create_next_invoice( to_date=nil )
    invoice = self.build_next_invoice(to_date)
    invoice.save
    invoice
  end
  
  def settle_next_invoice( to_date=nil )
    invoice = self.build_next_invoice( to_date )
    invoice.settle
    return invoice
  end
  
  ##
  # Generate a new FreshBooks invoice.
  def create_freshbook_invoice( to_date=nil )
    to_date ||= DateTime.yesterday.end_of_day
    invoice = self.invoices.build date_to: to_date
    invoice.create_invoice!
  end
  
  def last_invoice_date()

    # Get last invoice date
    date = self.invoices.maximum('date_to')
    date = (date + 1.day).beginning_of_day if date

    # Get first ledger entry
    unless date
      date = self.ledger_entries.minimum('created_at')
      date = date.beginning_of_day if date
    end
    
    # Finally, throw an error
    raise FreshBooksError.new( 'Cannot create a new invoice as there are no transactions to record' ) if date.nil?
    return date.to_time
  end
  
  def assemble_freshbooks_payment_data( amount )
    { client_id: self.freshbooks_id, amount: amount, type: 'Credit' }
  end
  
  def record_freshbooks_payment( amount )
    raise SignalCloud::MissingFreshBooksClientError.new(self) if self.freshbooks_id.nil?
    data = assemble_freshbooks_payment_data( amount )
    FreshBooks.account.payment.create({ payment: data })
  end
  
  def freshbooks_credits
    credits = self.freshbooks_client['credits']
    credits = [ credits ] unless credits.is_a? Array
    credits.each_with_object(HashWithIndifferentAccess.new) do |credit, h|
      currency = credit['credit']['currency']
      amount = BigDecimal.new credit['credit']['__content__']
      h[currency] = amount
    end
  end
  
end
