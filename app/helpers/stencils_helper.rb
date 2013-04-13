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
      { label: 'Show all stencils', link: stencils_path },
      { label: 'Show active stencils', link: active_stencils_path },
      { label: 'Show inactive stencils', link: inactive_stencils_path }
      ])
  end

end
