json.array!(@contracts) do |contract|
  json.extract! contract, :id, :name, :instance_id, :smash_client
  json.url contract_url(contract, format: :json)
end
