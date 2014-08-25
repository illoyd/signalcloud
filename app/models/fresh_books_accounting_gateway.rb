class FreshBooksAccountingGateway < AccountingGateway

  attr_encrypted :remote_sid, key: Rails.application.secrets.encrypted_secret

  alias_method :freshbooks_id, :remote_sid
  alias_method :freshbooks_id=, :remote_sid=

  def has_remote_instance?
    !self.freshbooks_id.blank?
  end
  
  alias_method :has_freshbooks_client?, :has_remote_instance?
  
  def has_contact_details?
    !self.organization.contact_address.nil? rescue false
  end

  ##
  # Get the current client's FreshBook organization, using the FreshBook global module.
  # In FreshBooks parlance, this is a 'Client' object.
  def remote_instance
    raise SignalCloud::MissingFreshBooksClientError.new(self) unless self.has_freshbooks_client?
    response = FreshBooks.account.client.get(client_id: self.freshbooks_id)
    raise SignalCloud::FreshBooksError.new( 'API Error: %s (%i)' % [response['error'], response['code']], response['code'] ) unless response.success?
    response['client']
  end
  
  alias_method :freshbooks_client, :remote_instance
  
#   ##
#   # Helper method to create or update as necessary
#   def create_or_update_remote
#     self.has_freshbooks_client? ? self.update_freshbooks_client! : self.create_freshbooks_client!
#   end
#   
#   alias_method :create_or_update_freshbooks_client!, :create_or_update_remote
# 

  ##
  # Query remote service for available credits on this account.
  def available_credits
    credits = self.freshbooks_client['credits']
    credits = [ credits ] unless credits.is_a? Array
    credits.each_with_object(HashWithIndifferentAccess.new) do |credit, h|
      currency = credit['credit']['currency']
      amount = BigDecimal.new credit['credit']['__content__']
      h[currency] = amount
    end
  end
  
  def record_credit( amount )
    raise SignalCloud::MissingFreshBooksClientError.new(self) unless self.has_freshbooks_client?
    data = self.assemble_freshbooks_payment_data( amount )
    FreshBooks.account.payment.create(data)
  end

  alias_method :freshbooks_credits, :available_credits
  alias_method :create_freshbooks_client!, :create_remote!
  alias_method :update_freshbooks_client!, :update_remote!

protected
  
  ##
  # Create a new FreshBooks client for this organization. This method will throw an error if a FreshBooks client already exists.
  def create_remote
    raise SignalCloud::FreshBooksClientAlreadyExistsError.new(self) if self.has_freshbooks_client?
    raise SignalCloud::MissingContactDetailsError.new(self) unless self.has_contact_details?
    
    # Instruct FreshBooks API to create the organization, then save the resulting ID
    response = FreshBooks.account.client.create(self.assemble_freshbooks_client_data)
    
    # If this is a duplicate, try to find and re-use the account based on the email
    if response.fetch('code', 0) == 40068.to_s
      response = self.find_freshbooks_client_by_email

    # Otherwise, raise error
    else
      raise SignalCloud::FreshBooksError.new( 'API Error: %s (%i)' % [response['error'], response['code']], response['code'] ) unless response.success?
    end
    
    # Finally, save!
    self.freshbooks_id = response['client_id']
    self.save!
  end
  
  def update_remote
    raise SignalCloud::MissingFreshBooksClientError.new(self) unless self.has_freshbooks_client?
    raise SignalCloud::MissingContactDetailsError.new( self ) unless self.has_contact_details?

    # Instruct FreshBooks API to update the organization, then save the resulting ID
    response = FreshBooks.account.client.update(self.assemble_freshbooks_client_data)
    raise SignalCloud::FreshBooksError.new( 'API Error: %s (%i)' % [response['error'], response['code']], response['code'] ) unless response.success?
    self.save!
  end
    
#   def find_by_email
#     raise SignalCloud::MissingContactDetailsError.new( self ) if self.contact_address.nil?
#     response = FreshBooks.account.client.list({ email: self.contact_address.email })
#     raise SignalCloud::FreshBooksError.new( 'API Error: %s (%i)' % [response['error'], response['code']], response['code'] ) unless response.success?
#     return response.fetch('clients', {}).fetch('client', nil)
#   end
  
#   alias_method :find_freshbooks_client_by_email, :find_by_email

  def assemble_remote_data( additional_data={} )
    # Construct the complete client dataset to be passed to FreshBooks
    client_data = {
      organization: self.organization.label,
      currency_code: FreshBooks::DEFAULT_CURRENCY
    }
    
    # Add client data if already set
    client_data[:client_id] = self.freshbooks_id if self.has_freshbooks_client?
    
    # Insert primary address if appropriate
    unless self.organization.billing_address.nil?
      client_data.merge!({
        # Add billing contact
        first_name: self.organization.billing_address.first_name,
        last_name:  self.organization.billing_address.last_name,
        #username:   self.billing_address.email,
        email:      self.organization.billing_address.email,
        work_phone: self.organization.billing_address.work_phone,

        # Add address
        p_street1:  self.organization.billing_address.line1,
        p_street2:  self.organization.billing_address.line2,
        p_city:     self.organization.billing_address.city,
        p_state:    self.organization.billing_address.region,
        p_country:  self.organization.billing_address.country,
        p_code:     self.organization.billing_address.postcode
      })
    end
    
    # Insert secondary address if needed
    unless self.organization.contact_address.nil?
      client_data.merge!({
        s_street1:  self.organization.contact_address.line1,
        s_street2:  self.organization.contact_address.line2,
        s_city:     self.organization.contact_address.city,
        s_state:    self.organization.contact_address.region,
        s_country:  self.organization.contact_address.country,
        s_code:     self.organization.contact_address.postcode
      })
    end
    
    # Insert VAT data if appropriate
    client_data[:vat_name]   unless self.organization.vat_name.blank?
    client_data[:vat_number] unless self.organization.vat_number.blank?

    # Add purchase order
    client_data[:purchase_order] unless self.organization.purchase_order.blank?
    
    # If additional data is passed
    if additional_data.is_a? Hash
      client_data.merge! additional_data
    end
    
    # Wrap in a client identifier
    { client: client_data }
  end
  
  alias_method :assemble_freshbooks_client_data, :assemble_remote_data

  def assemble_remote_payment_data( amount, type='Credit', additional_data={} )
    payment_data = {
      client_id: self.freshbooks_id,
      amount: amount,
      type: type }

    payment_data.merge!( additional_data ) if additional_data.is_a? Hash

    { payment: payment_data }
  end
  
  alias_method :assemble_freshbooks_payment_data, :assemble_remote_payment_data

end
