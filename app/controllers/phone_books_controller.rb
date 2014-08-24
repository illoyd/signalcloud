class PhoneBooksController < ProtectedController

  respond_to :html, :json, :xml
  load_and_authorize_resource :organization
  before_filter :load_new_phone_book, only: [ :new, :create ]
  load_and_authorize_resource through: :organization

  def load_new_phone_book
    @phone_book = PhoneBook.new( organization_id: @organization.id )
    @phone_book
  end
  
  # GET /phone_books
  # GET /phone_books.json
  def index
    # Apply an active/inactive filter if requested
    #     if ( params.include? :active_filter )
    #       @phone_books = @phone_books.where( active: params[:active_filter] )
    #     end

    respond_with @organization, @phone_books
  end

  # GET /phone_books/1
  # GET /phone_books/1.json
  def show
    respond_with @organization, @phone_book
  end

  # GET /phone_books/new
  # GET /phone_books/new.json
  def new
    respond_with @organization, @phone_book
  end

  # GET /phone_books/1/edit
  def edit
    respond_with @organization, @phone_book
  end

  # POST /phone_books
  # POST /phone_books.json
  def create
    flash[:success] = 'Your new phone book has been saved.' if @phone_book.update_attributes(phone_book_params)
    respond_with @organization, @phone_book
  end

  # PUT /phone_books/1
  # PUT /phone_books/1.json
  def update
    flash[:success] = 'Your phone book has been updated.' if @phone_book.update_attributes(phone_book_params)
    respond_with @organization, @phone_book
  end

  # DELETE /phone_books/1
  # DELETE /phone_books/1.json
  def destroy
    flash[:success] = 'Your phone book has been deleted.' if @phone_book.destroy
    respond_with @organization, @phone_book
  end
end
