json.array!(@phone_books) do |phone_book|
  json.extract! phone_book, :id, :team_id, :workflow_state, :name, :description
  json.url phone_book_url(phone_book, format: :json)
end
