class Account < ActiveRecord::Base

  ##
  # Get the current client's FreshBook account, using the FreshBook global module.
  # In FreshBooks parlance, this is a 'Client' object.
  def freshbooks_client
    raise SignalCloud::MissingFreshBooksClientError.new(self) if self.freshbooks_id.blank?
    Freshbooks.account.client.get client_id: self.freshbooks_id
  end
  
  ##
  # Create a new FreshBooks client for this account. This method will throw an error if a FreshBooks client already exists.
  def create_freshbooks_client
    raise SignalCloud::FreshBooksClientAlreadyExistsError.new(self) unless self.freshbooks_id.nil?
    raise SignalCloud::FreshBooksError.new( 'Missing a primary contact.' ) if self.primary_address.nil?
    
    # Construct the complete client dataset to be passed to Freshbooks
    contact = self.users.first
    client_data = {
      organisation: self.label,
      currency_code: Freshbooks::DEFAULT_CURRENCY
    }
    
    # Insert primary address if appropriate
    unless self.primary_address.nil?
      client_data.merge!({
        # Add primary contact
        first_name: self.primary_address.first_name,
        last_name:  self.primary_address.last_name,
        username:   self.primary_address.email,
        email:      self.primary_address.email,
        work_phone: self.primary_address.work_phone,
        # Add address
        p_street1:  self.primary_address.line1,
        p_street2:  self.primary_address.line2,
        p_city:     self.primary_address.city,
        p_state:    self.primary_address.region,
        p_country:  self.primary_address.country,
        p_code:     self.primary_address.postcode
      })
    end
    
    # Insert secondary address if appropriate
    unless self.secondary_address.nil?
      client_data.merge!({
        s_street1:  self.secondary_address.line1,
        s_street2:  self.secondary_address.line2,
        s_city:     self.secondary_address.city,
        s_state:    self.secondary_address.region,
        s_country:  self.secondary_address.country,
        s_code:     self.secondary_address.postcode
      })
    end
    
    # Insert VAT data if appropriate
    client_data[:vat_name] unless self.vat_name.blank?
    client_data[:vat_number] unless self.vat_number.blank?
    
    # Instruct FreshBooks API to create the account, then save the resulting ID
    response = Freshbooks.account.client.create(client_data)
    self.freshbooks_id = response['client_id']
    self.save!
  end
  
  def build_next_invoice( to_date=nil, from_date=nil )
    from_date ||= (self.last_invoice_date + 1.day).beginning_of_day
    to_date ||= DateTime.yesterday.end_of_day
    return self.invoices.build date_from: from_date, date_to: to_date
  end
  
  def settle_next_invoice( to_date=nil, from_date=nil )
    invoice = self.build_next_invoice( to_date, from_date )
    invoice.settle
    return invoice
  end
  
  ##
  # Generate a new FreshBooks invoice.
  def create_freshbook_invoice( to_date=nil, from_date=nil )
    from_date ||= (self.invoices.last.date_to + 1.day).beginning_of_day
    to_date ||= DateTime.yesterday.end_of_day
    invoice = self.invoices.build date_from: from_date, date_to: to_date
    invoice.create_invoice!
  end
  
end
