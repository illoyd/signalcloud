class ConversationsController < ApplicationController

  respond_to :html, :json, :xml
  load_and_authorize_resource :organization
  before_filter :load_stencil
  authorize_resource :stencil
  before_filter :load_new_conversation, only: [ :new, :create ]
  load_and_authorize_resource through: :organization

  def load_stencil
    @stencil = params[:stencil_id] ? @organization.stencils.find(params[:stencil_id]) : nil
  end

  def load_new_conversation
    @conversation = @stencil.build_conversation()
    @conversation
  end
  
  # GET /conversations
  # GET /conversations.json
  def index
    
    @multistencil = @stencil.nil?
    unless @multistencil
      @conversations = @conversations.where( stencil_id: @stencil.id )
    end
    
    unless params[:status].nil?
      @conversations = @conversations.where( status: params[:status] )
    end

    # Add pagination
    @conversations = @conversations.order( 'updated_at desc' ).page( params[:page] )

    respond_with @organization, @conversations
  end

  # GET /conversations/1
  # GET /conversations/1.json
  def show
    respond_with @organization, @conversation
  end

  # GET /conversations/new
  # GET /conversations/new.json
  def new
    respond_with @organization, @conversation
  end

  # GET /conversations/1/edit
  #   def edit
  #     @conversation = ( @stencil.nil? ? @organization : @stencil ).conversations.find(params[:id])
  #   end

  # POST /conversations
  # POST /conversations.json
  def create
    # @conversation = ( @stencil.nil? ? @organization : @stencil ).conversations.create( params[:conversation] )
    #@conversation = @stencil.open_conversation( conversation_params )
    #authorize!( :create, @conversation )

    if @conversation.update_attributes( conversation_params )
      #JobTools.enqueue SendConversationChallengeJob.new( @conversation.id )
      flash[:success] = 'The conversation has been successfully started.'
    end
    respond_with @organization, @conversation
  end

  # PUT /conversations/1
  # PUT /conversations/1.json
  #   def update
  #     @conversation = ( @stencil.nil? ? @organization : @stencil ).conversations.find(params[:id])
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
  #     @conversation = ( @stencil.nil? ? @organization : @stencil ).conversations.find(params[:id])
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
