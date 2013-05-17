class PhoneNumbersController < ApplicationController

  load_and_authorize_resource
  before_filter :assign_organization

  respond_to :html

  # GET /phone_numbers
  # GET /phone_numbers.json
  def index
    @phone_numbers = current_organization.phone_numbers #.order()
    respond_with @phone_numbers
  end

  # GET /phone_numbers/1
  # GET /phone_numbers/1.json
  #def show
  #  @phone_number = PhoneNumber.find(params[:id])
  #
  #  respond_to do |format|
  #    format.html # show.html.erb
  #    format.json { render json: @phone_number }
  #  end
  #end

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

    # Purchase the number
    @phone_number = current_organization.phone_numbers.build( params )
    begin
      # @phone_number.buy
      flash[:success] = 'Phone number was successfully created.' if @phone_number.save
      respond_with @phone_number

    rescue Twilio::Rest::RequestError => ex
      case ex.code
        when 21452
          flash[:error] = 'Number not available. (%s)' % [ex.message]
        else
          flash[:error] = 'Unknown error! (%s)' % [ex.message]
      end
      redirect_to search_organization_phone_numbers_path(@organization)
    end
  end

  # PUT /phone_numbers/1
  # PUT /phone_numbers/1.json
  def update
   @phone_number = current_organization.phone_numbers.find(params[:id])
  
   respond_to do |format|
     if @phone_number.update_attributes(params[:phone_number])
       format.html { redirect_to @phone_number, notice: 'Phone number was successfully updated.' }
       format.json { head :no_content }
     else
       format.html { render action: "edit" }
       format.json { render json: @phone_number.errors, status: :unprocessable_entity }
     end
   end
  end

  # DELETE /phone_numbers/1
  # DELETE /phone_numbers/1.json
  #def destroy
  #  @phone_number = PhoneNumber.find(params[:id])
  #  @phone_number.destroy
  #
  #  respond_to do |format|
  #    format.html { redirect_to phone_numbers_url }
  #    format.json { head :no_content }
  #  end
  #end
  
  def search
    # Collection of searchable params
    allowed_search_params = [ :area_code, :contains, :in_region, :in_postal_code, :near_number, :distance ]
    search_params = allowed_search_params.each_with_object({}) { |k, h| h[k] = params[k] if params.include?(k) }
    
    # Extract country code from params
    country_code = params[:country].upcase
    
    # Search and reply
    begin
      @available_phone_numbers = current_organization.twilio_account.available_phone_numbers.get( country_code ).local.list( search_params )
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
#       @available_phone_numbers = current_organization.twilio_client.incoming_phone_numbers.create({:phone_number => phone_number_to_buy})
#     rescue Twilio::Rest::RequestError => ex
#       if ex.code = 21452
#         flash[:error] = 'Number not available. (%s)' % [ex.message]
#       else
#         flash[:error] = 'Unknown error! (%s)' % [ex.message] 
#       end
#     end
#   end

end
