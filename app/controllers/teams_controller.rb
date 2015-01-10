class TeamsController < ProtectedController
  before_action :set_team, only: [:show, :edit, :update, :destroy]

  respond_to :html

  decorates_assigned :teams, :team

  def index
    @teams = policy_scope(Team).order(:name)
    respond_with(@teams)
  end

  def show
    respond_with(@team)
  end

  def new
    @team = Team.new(owner: current_user)
    authorize @team
    respond_with(@team)
  end

  def edit
    respond_with(@team)
  end

  def create
    @team = Team.new(team_params)
    @team.owner = current_user
    authorize @team

    flash[:success] = 'Hooray!' if @team.save
    respond_with(@team)
  end

  def update
    flash[:success] = 'Hooray!' if @team.update(team_params)
    respond_with(@team)
  end

  private
    def set_team
      @team = Team.find(params[:id])
      authorize @team
    end

    def team_params
      params.require(:team).permit(:name, :description)
    end
end
