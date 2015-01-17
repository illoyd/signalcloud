class PhoneBookEntriesController < ProtectedController
  before_action :set_phone_book_entry, only: [:update, :destroy]

  respond_to :html

  def create
    @phone_book_entry = PhoneBookEntry.new(phone_book_entry_params)
    authorize @phone_book_entry
    authorize @phone_book_entry.phone_book, :show?
    authorize @phone_book_entry.phone_number, :show?

    flash[:success] = "#{ @phone_book_entry.phone_number.number } was added to #{ @phone_book_entry.phone_book.name }." if @phone_book_entry.save
    redirect_to :back
  end

  def update
    @phone_book_entry.assign_attributes(phone_book_entry_params)
    authorize @phone_book_entry.phone_book, :show?   if @phone_book_entry.phone_book.present?
    authorize @phone_book_entry.phone_number, :show? if @phone_book_entry.phone_number.present?
    flash[:success] = "#{ @phone_book_entry.phone_number.number }'s entry in #{ @phone_book_entry.phone_book.name } was updated." if @phone_book_entry.save
    redirect_to :back
  end
  
  def destroy
    flash[:success] = "#{ @phone_book_entry.phone_number.number } was removed from #{ @phone_book_entry.phone_book.name }." if @phone_book_entry.destroy
    redirect_to :back
  end

  private
    def set_phone_book_entry
      @phone_book_entry = PhoneBookEntry.find(params[:id])
      authorize @phone_book_entry
    end

    def phone_book_entry_params
      params.require(:phone_book_entry).permit(:phone_book_id, :phone_number_id, :country)
    end
end
