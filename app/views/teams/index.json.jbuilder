json.array!(@teams) do |team|
  json.extract! team, :id, :user_id, :workflow_state, :name, :description
  json.url team_url(team, format: :json)
end
