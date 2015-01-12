class PhoneNumbersController < ProtectedController
  before_action :set_team,         only: [:index, :new]
  before_action :set_phone_number, only: [:show, :edit, :update, :destroy]

  respond_to :html
  
  decorates_assigned :phone_numbers, :phone_number

  def index
    @phone_numbers = policy_scope(@team.phone_numbers).order(:number)
    respond_with(@phone_numbers)
  end

  def show
    respond_with(@phone_number)
  end

  def edit
    respond_with(@phone_number)
  end

  def update
    flash[:success] = 'Hooray!' if @phone_number.update(phone_number_params)
    respond_with(@phone_number)
  end
  
  def purchase
  end
  
  def release
  end

  private
    def set_phone_number
      @phone_number = PhoneNumber.find(params[:id])
      authorize @phone_number

      @team         = @phone_number.team
      authorize @team, :show?
    end

    def phone_number_params
      params.require(:phone_number).permit(:team_id)
    end
end
