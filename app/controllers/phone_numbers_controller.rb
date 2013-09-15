class PhoneNumbersController < ApplicationController

  before_filter :assign_organization
  load_and_authorize_resource
  skip_load_and_authorize_resource only: [ :index, :create, :search ]

  respond_to :html

  # GET /phone_numbers
  # GET /phone_numbers.json
  def index
    @phone_numbers = @organization.phone_numbers
    authorize! :index, PhoneNumber
    respond_with @phone_numbers
  end

  # GET /phone_numbers/1
  # GET /phone_numbers/1.json
  def show
    respond_with @phone_number
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
  #def edit
  #  @phone_number = PhoneNumber.find(params[:id])
  #end

  # POST /phone_numbers
  # POST /phone_numbers.json
  def create

    # Construct and authorise the phone number
    @phone_number = @organization.phone_numbers.build( params )
    authorize! :create, @phone_number

    begin
      @phone_number.buy
      flash[:success] = 'Phone number was successfully created.' if @phone_number.save
      respond_with [@organization, @phone_number]

    rescue Twilio::Rest::RequestError => ex
      case ex.code
        when Twilio::ERR_PHONE_NUMBER_NOT_AVAILABLE
          flash[:error] = 'Phone number not available. (%s)' % [ex.message]
        else
          flash[:error] = 'Unknown error! (%i: %s)' % [ex.code, ex.message]
      end
      redirect_to search_organization_phone_numbers_path(@organization)
    end
  end

  # PUT /phone_numbers/1
  # PUT /phone_numbers/1.json
  def update
    flash[:success] = 'Phone number was successfully updated.' if @phone_number.update_attributes(params[:phone_number])
    respond_with [@organization, @phone_number]
  end

  # DELETE /phone_numbers/1
  # DELETE /phone_numbers/1.json
  def destroy
    @phone_number.unbuy
    @phone_number.destroy

    respond_to do |format|
      format.html { redirect_to organization_phone_numbers_url(@organization) }
      format.json { head :no_content }
    end
  end
  
  def search
    # Number of phone numbers to show
    @numbers_to_show = 10
  
    # Collection of searchable params
    allowed_search_params = [ :area_code, :contains, :in_region, :in_postal_code, :near_number, :distance ]
    search_params = allowed_search_params.each_with_object({}) { |k, h| h[k] = params[k] if params.include?(k) }
    
    # Extract country code from params
    country_code = params.fetch(:country, 'US').upcase
    
    # Search and reply
    begin
      @available_phone_numbers = @organization.twilio_account.available_phone_numbers.get( country_code ).local.list( search_params ).first(@numbers_to_show)
      respond_with @available_phone_numbers
    rescue Twilio::REST::RequestError => ex
      flash.now[:error] = '%s (%s)' % [ ex.message, ex.code ]
      @available_phone_numbers = []
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

end
