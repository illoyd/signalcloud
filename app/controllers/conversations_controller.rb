class ConversationsController < ApplicationController

  respond_to :html, :json, :xml
  before_filter :setup_account_and_stencil

  load_and_authorize_resource
  skip_authorize_resource only: [:new, :create]
  
  def setup_account_and_stencil
    @account = current_account()
    @stencil = current_stencil(false)
  end
  
  # GET /conversations
  # GET /conversations.json
  def index
    if @stencil.nil?
      redirect_to stencil_conversations_path(current_stencil(true))
      return
    end

    @multistencil = @stencil.nil?
    if !@multistencil
      @conversations = @conversations.where( stencil_id: @stencil.id )
    end
    
    unless params[:status].nil?
      @conversations = @conversations.where( status: params[:status] )
    end
    
    # Add pagination
    @conversations = @conversations.page(params[:page])

    respond_with @conversations
  end

  # GET /conversations/1
  # GET /conversations/1.json
  def show
    # @conversation = ( @stencil.nil? ? @account : @stencil ).conversations.find(params[:id])
    respond_with @conversation
  end

  # GET /conversations/new
  # GET /conversations/new.json
  def new
    @conversation = @stencil.open_conversation({})
    authorize!( :new, @conversation )
  end

  # GET /conversations/1/edit
  #   def edit
  #     @conversation = ( @stencil.nil? ? @account : @stencil ).conversations.find(params[:id])
  #   end

  # POST /conversations
  # POST /conversations.json
  def create
    # @conversation = ( @stencil.nil? ? @account : @stencil ).conversations.create( params[:conversation] )
    @conversation = @stencil.open_conversation( params[:conversation] )
    authorize!( :create, @conversation )

    if @conversation.save
      JobTools.enqueue SendConversationChallengeJob.new( @conversation.id )
      flash[:success] = 'The conversation has been successfully started.'
    end
    respond_with @conversation
  end

  # PUT /conversations/1
  # PUT /conversations/1.json
  #   def update
  #     @conversation = ( @stencil.nil? ? @account : @stencil ).conversations.find(params[:id])
  # 
  #     respond_to do |format|
  #       if @conversation.update_attributes(params[:conversation])
  #         format.html { redirect_to @conversation, notice: 'Conversation was successfully updated.' }
  #         format.json { head :no_content }
  #       else
  #         format.html { render action: "edit" }
  #         format.json { render json: @conversation.errors, status: :unprocessable_entity }
  #       end
  #     end
  #   end

  # DELETE /conversations/1
  # DELETE /conversations/1.json
  #   def destroy
  #     @conversation = ( @stencil.nil? ? @account : @stencil ).conversations.find(params[:id])
  #     @conversation.destroy
  # 
  #     respond_to do |format|
  #       format.html { redirect_to conversations_url }
  #       format.json { head :no_content }
  #     end
  #   end
  
  ##
  # Allow 'forcing' the status of a conversation.
  def force
    
  end

end
