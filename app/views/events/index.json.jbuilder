json.array!(@events) do |event|
  json.extract! event, :id
  json.extract! event, :title, :description
  json.start event.begin_datetime
  json.end event.end_datetime
  json.url event_url(event, format: :html)
end