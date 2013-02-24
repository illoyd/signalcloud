module AccountsHelper

  def ticket_status_breakdown( counts )
    counts = Ticket.count_by_status_hash(counts) if counts.is_a? ActiveRecord::Relation
    total = counts.values.sum().to_f
    statistics = counts.each_with_object({}) do |(k, v), h|
      h[k] = v.to_f / total * 100.0
    end
    render partial: 'ticket_status_breakdown', locals: { counts: counts, statistics: statistics, total: total }
  end

end
