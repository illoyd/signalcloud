module InvoicesHelper

  def status_tag_for(invoice)
    llabel( invoice.workflow_state, invoice.workflow_state )
  end
  
end
