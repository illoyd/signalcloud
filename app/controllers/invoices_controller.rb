class InvoicesController < ProtectedController

  respond_to :html, :json, :xml
  load_and_authorize_resource :organization
  load_and_authorize_resource through: :organization, except: [:pending]
  before_action :load_and_authorize_pending_invoice, only: [:pending]

  # GET /invoices
  # GET /invoices.json
  def index
    # Apply pagination
    @invoices = @invoices.page(params[:page])
    respond_with @organization, @invoices
  end

  # GET /invoices/1
  # GET /invoices/1.json
  def show
    @ledger_entries = @invoice.ledger_entries.page(params[:page])
    respond_with @organization, @invoice
  end

  # GET /invoices/pending
  # GET /invoices/pending.json
  def pending
    @ledger_entries = @organization.ledger_entries.uninvoiced.page(params[:page])
    respond_with @organization, @invoice
  end
  
  private
  
  def load_and_authorize_pending_invoice
    @invoice = Invoice.new(organization: @organization)
    authorize! :show, @invoice
  end

end
