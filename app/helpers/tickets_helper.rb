module TicketsHelper
 
  def appliance_dropdown_list( current_account, current_appliance )
    # Pick the dropdown list title
    title = 'Current Filter: ' + ( current_appliance.nil? ? 'All' : current_appliance.label )
    
    # Assemble the entries based upon the current
    entries = [ { label: 'Show all tickets', icon: 'ok-circle', link: tickets_path } ]
    current_account.appliances( order: :label ).each do |appliance|
      entries << { label: 'Filter by ' + appliance.label, icon: :appliances, link: appliance_tickets_path( appliance ) }
    end
    
    dropdown_list( title, entries )
  end
end
