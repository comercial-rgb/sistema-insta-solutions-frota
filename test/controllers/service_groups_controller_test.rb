require "test_helper"

class ServiceGroupsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get service_groups_index_url
    assert_response :success
  end

  test "should get new" do
    get service_groups_new_url
    assert_response :success
  end

  test "should get create" do
    get service_groups_create_url
    assert_response :success
  end

  test "should get edit" do
    get service_groups_edit_url
    assert_response :success
  end

  test "should get update" do
    get service_groups_update_url
    assert_response :success
  end

  test "should get destroy" do
    get service_groups_destroy_url
    assert_response :success
  end
end
