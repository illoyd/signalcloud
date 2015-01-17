class StencilsController < ProtectedController
  before_action :set_team,    only: [:index, :new, :create]
  before_action :set_stencil, only: [:show, :edit, :update]

  respond_to :html

  decorates_assigned :stencils, :stencil

  def index
    @stencils = policy_scope(@team.stencils)
    respond_with(@stencils)
  end

  def show
    respond_with(@stencil)
  end

  def new
    @stencil = @team.stencils.build
    respond_with(@stencil)
  end

  def edit
  end

  def create
    @stencil = @team.stencils.build(stencil_params)
    authorize @stencil

    @stencil.save
    respond_with(@stencil)
  end

  def update
    @stencil.update(stencil_params)
    respond_with(@stencil)
  end

  def destroy
    @stencil.destroy
    respond_with(@stencil)
  end

  private
    def set_stencil
      @stencil = Stencil.find(params[:id])
      authorize @stencil
      
      @team = @stencil.team
      authorize @team, :show?
    end

    def stencil_params
      params.require(:stencil).permit(:team_id, :workflow_state, :name, :description, :phone_book_id)
    end
end
