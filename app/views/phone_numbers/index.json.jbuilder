json.array!(@phone_numbers) do |phone_number|
  json.extract! phone_number, :id, :type, :team_id, :workflow_state, :number, :provider_sid
  json.url phone_number_url(phone_number, format: :json)
end
