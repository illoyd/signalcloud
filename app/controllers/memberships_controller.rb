class MembershipsController < ProtectedController
  before_action :set_membership, only: [:update, :destroy]

  respond_to :html

  def create
    @membership = Membership.new(membership_params)
    authorize @membership

    flash[:success] = "#{ @membership.user.name } was added to #{ @membership.team.name }." if @membership.save
    redirect_to :back
  end

  def update
    flash[:success] = "#{ @membership.user.name }'s membership in #{ @membership.team.name } was updated." if @membership.update(membership_params)
    redirect_to :back
  end
  
  def destroy
    flash[:success] = "#{ @membership.user.name } was removed from #{ @membership.team.name }." if @membership.destroy
    redirect_to :back
  end

  private
    def set_membership
      @membership = Membership.find(params[:id])
      authorize @membership
    end

    def membership_params
      params.require(:membership).permit(:user_id, :team_id, :administrator, :developer, :billing_liaison, :conversation_manager)
    end
end
