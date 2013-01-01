module AppliancesHelper

  def filter_dropdown_list
    # Build the filter title
    filter = 'All appliances'

    if params.include? :active_filter
      filter = params[:active_filter] ? 'Active appliances' : 'Inactive appliances'
    end

    label = '%s Current Filter: %s' % [ icon( :filter ), filter ]
    label = 'Current Filter: %s' % [ filter ]
    return dropdown_list( label, [
      { label: 'Show all appliances', link: appliances_path },
      { label: 'Show active appliances', link: active_appliances_path },
      { label: 'Show inactive appliances', link: inactive_appliances_path }
      ])
  end

end
