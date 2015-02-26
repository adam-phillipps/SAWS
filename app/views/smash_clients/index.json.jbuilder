json.array!(@smash_clients) do |smash_client|
  json.extract! smash_client, :id, :name, :user
  json.url smash_client_url(smash_client, format: :json)
end
