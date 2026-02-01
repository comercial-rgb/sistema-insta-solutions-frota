require "test_helper"

class VehicleModelsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get vehicle_models_index_url
    assert_response :success
  end

  test "should get new" do
    get vehicle_models_new_url
    assert_response :success
  end

  test "should get create" do
    get vehicle_models_create_url
    assert_response :success
  end

  test "should get edit" do
    get vehicle_models_edit_url
    assert_response :success
  end

  test "should get update" do
    get vehicle_models_update_url
    assert_response :success
  end

  test "should get destroy" do
    get vehicle_models_destroy_url
    assert_response :success
  end
end
