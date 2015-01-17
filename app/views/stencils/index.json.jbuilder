json.array!(@stencils) do |stencil|
  json.extract! stencil, :id, :team_id, :workflow_state, :name, :description, :phone_book_id
  json.url stencil_url(stencil, format: :json)
end
