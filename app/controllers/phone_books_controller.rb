class PhoneBooksController < ProtectedController
  before_action :set_team,       only: [:index, :new]
  before_action :set_phone_book, only: [:show, :edit, :update]

  respond_to :html

  decorates_assigned :phone_books, :phone_book

  def index
    @phone_books = policy_scope(@team.phone_books).order(:name)
    respond_with(@phone_books)
  end

  def show
    respond_with(@phone_book)
  end

  def new
    @phone_book = @team.phone_books.build
    respond_with(@phone_book)
  end

  def edit
    respond_with(@phone_book)
  end

  def create
    @phone_book = PhoneBook.new(phone_book_params)
    flash[:success] = 'Phone book successfully created.' if @phone_book.save
    respond_with(@phone_book)
  end

  def update
    flash[:success] = 'Phone book successfully updated.' if @phone_book.update(phone_book_params)
    respond_with(@phone_book)
  end

  private
    def set_phone_book
      @phone_book = PhoneBook.find(params[:id])
      authorize @phone_book
      
      @team = @phone_book.team
      authorize @team, :show?
    end

    def phone_book_params
      params.require(:phone_book).permit(:team_id, :workflow_state, :name, :description)
    end
end
