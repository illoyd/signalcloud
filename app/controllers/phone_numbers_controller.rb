class PhoneNumbersController < ProtectedController

  respond_to :html, :json, :xml
  load_and_authorize_resource :organization
  load_and_authorize_resource through: :organization
  # skip_load_and_authorize_resource only: [ :index, :create, :search ]

  # GET /phone_numbers
  # GET /phone_numbers.json
  def index
    respond_with @organization, @phone_numbers
  end

  # GET /phone_numbers/1
  # GET /phone_numbers/1.json
  def show
    respond_with @organization, @phone_number
  end

  # GET /phone_numbers/new
  # GET /phone_numbers/new.json
  #def new
  #  @phone_number = PhoneNumber.new
  #
  #  respond_to do |format|
  #    format.html # new.html.erb
  #    format.json { render json: @phone_number }
  #  end
  #end

  # GET /phone_numbers/1/edit
  def edit
    respond_with @organization, @phone_number
  end

  # POST /phone_numbers
  # POST /phone_numbers.json
  def create

    # Construct and authorise the phone number
    @phone_number = @organization.phone_numbers.build( buy_phone_number_params )
    @phone_number.communication_gateway = @organization.communication_gateway_for(:twilio)
    authorize! :create, @phone_number

    begin
      @phone_number.purchase!
      flash[:success] = 'Phone number was successfully created.' if @phone_number.update(buy_phone_number_params)

    rescue Twilio::REST::RequestError => ex
      case ex.code
        when Twilio::ERR_PHONE_NUMBER_NOT_AVAILABLE
          flash[:error] = "Sorry, #{ view_context.humanize_phone_number @phone_number.number } is no longer available. (Detailed message: #{ ex.message })"
        else
          flash[:error] = 'Unknown error! (%s: %s)' % [ex.code, ex.message]
      end
    ensure
      respond_with @organization, @phone_number
    end
  end

  # PUT /phone_numbers/1
  # PUT /phone_numbers/1.json
  def update
    flash[:success] = 'Phone number was successfully updated.' if @phone_number.update_attributes(phone_number_params)
    respond_with @organization, @phone_number
  end

  def new
    @phone_number = nil
    
    # Number of phone numbers to show
    @numbers_to_show = 10
  
    # Pick the searchable parameters
    search_params = params.slice( :area_code, :contains, :in_region, :in_postal_code, :near_number, :distance )
    search_params[:sms_enabled] = true
    
    # Extract country code from params
    country_code = params.fetch('country', 'US').upcase
    phone_number_kind = params.fetch('kind', 'local').downcase
    
    # Search and reply
    @available_phone_numbers = []
    begin
      @available_phone_numbers = search_for( country_code, phone_number_kind, search_params ).first(@numbers_to_show)
    rescue Twilio::REST::RequestError => ex
      flash.now[:error] = '%s (%s)' % [ ex.message, ex.code ]
      @available_phone_numbers = []
    ensure
      respond_with @available_phone_numbers
    end
  end

#   def buy
#     # Purchase the number
#     phone_number_to_buy = params[:phone_number]
#     begin
#       @available_phone_numbers = @organization.twilio_client.incoming_phone_numbers.create({:phone_number => phone_number_to_buy})
#     rescue Twilio::Rest::RequestError => ex
#       if ex.code = 21452
#         flash[:error] = 'Number not available. (%s)' % [ex.message]
#       else
#         flash[:error] = 'Unknown error! (%s)' % [ex.message] 
#       end
#     end
#   end

  def purchase
    begin
      if @phone_number.can_purchase?
        @phone_number.purchase!
        flash[:success] = 'Phone Number was successfully purchased.' if @phone_number.save
      else
        flash[:warning] = 'This Phone Number could not be purchased. It might already be active.'
      end

    rescue Twilio::REST::RequestError => ex
      case ex.code
        when Twilio::ERR_PHONE_NUMBER_NOT_AVAILABLE
          flash[:error] = "Sorry, #{ view_context.humanize_phone_number @phone_number.number } is no longer available. (Detailed message: #{ ex.message })"
        else
          flash[:error] = 'Unknown error! (%s: %s)' % [ex.code, ex.message]
      end
    ensure
      respond_with @organization, @phone_number
    end
  end
  
  def release
    begin
      if @phone_number.can_release?
        @phone_number.release!
        flash[:success] = 'Phone Number was successfully released.' if @phone_number.save
      else
        flash[:warning] = 'This Phone Number could not be released. It might already be inactive.'
      end

    rescue Twilio::REST::RequestError => ex
      case ex.code
        when Twilio::ERR_PHONE_NUMBER_NOT_AVAILABLE
          flash[:error] = "Sorry, #{ view_context.humanize_phone_number @phone_number.number } is no longer available. (Detailed message: #{ ex.message })"
        else
          flash[:error] = 'Unknown error! (%s: %s)' % [ex.code, ex.message]
      end
    ensure
      respond_with @organization, @phone_number
    end
  end

  protected
  
  def search_for(country, kind, search_params)
    searcher = search_gateway.available_phone_numbers.get(country)
    searcher = case kind
      when 'mobile'
        searcher.mobile
      else
        searcher.local
      end
    searcher.list(search_params)
  end
  
  def search_gateway
    @organization.communication_gateway_for(:twilio).try(:remote_instance) || Twilio.master_client.account
  end

end
