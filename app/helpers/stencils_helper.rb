module StencilsHelper

  def filter_dropdown_list
    # Build the filter title
    filter = 'All stencils'

    if params.include? :active_filter
      filter = params[:active_filter] ? 'Active stencils' : 'Inactive stencils'
    end

    label = '%s Current Filter: %s' % [ icon( :filter ), filter ]
    label = 'Current Filter: %s' % [ filter ]
    return dropdown_list( label, [
      { label: 'Show all stencils', link: organization_stencils_path(@organization) },
      { label: 'Show active stencils', link: active_organization_stencils_path(@organization) },
      { label: 'Show inactive stencils', link: inactive_organization_stencils_path(@organization) }
      ])
  end

end
