require 'test_helper'

class SmashClientsControllerTest < ActionController::TestCase
  setup do
    @smash_client = smash_clients(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:smash_clients)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create smash_client" do
    assert_difference('SmashClient.count') do
      post :create, smash_client: { name: @smash_client.name, user: @smash_client.user }
    end

    assert_redirected_to smash_client_path(assigns(:smash_client))
  end

  test "should show smash_client" do
    get :show, id: @smash_client
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @smash_client
    assert_response :success
  end

  test "should update smash_client" do
    patch :update, id: @smash_client, smash_client: { name: @smash_client.name, user: @smash_client.user }
    assert_redirected_to smash_client_path(assigns(:smash_client))
  end

  test "should destroy smash_client" do
    assert_difference('SmashClient.count', -1) do
      delete :destroy, id: @smash_client
    end

    assert_redirected_to smash_clients_path
  end
end
