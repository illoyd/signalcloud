require 'test_helper'

class AccountPlansControllerTest < ActionController::TestCase
  setup do
    @account_plan = account_plans(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:account_plans)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create account_plan" do
    assert_difference('AccountPlan.count') do
      post :create, account_plan: { call_in_add: @account_plan.call_in_add, call_in_mult: @account_plan.call_in_mult, label: @account_plan.label, month: @account_plan.month, phone_add: @account_plan.phone_add, phone_mult: @account_plan.phone_mult, sms_in_add: @account_plan.sms_in_add, sms_in_mult: @account_plan.sms_in_mult, sms_out_add: @account_plan.sms_out_add, sms_out_mult: @account_plan.sms_out_mult }
    end

    assert_redirected_to account_plan_path(assigns(:account_plan))
  end

  test "should show account_plan" do
    get :show, id: @account_plan
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @account_plan
    assert_response :success
  end

  test "should update account_plan" do
    put :update, id: @account_plan, account_plan: { call_in_add: @account_plan.call_in_add, call_in_mult: @account_plan.call_in_mult, label: @account_plan.label, month: @account_plan.month, phone_add: @account_plan.phone_add, phone_mult: @account_plan.phone_mult, sms_in_add: @account_plan.sms_in_add, sms_in_mult: @account_plan.sms_in_mult, sms_out_add: @account_plan.sms_out_add, sms_out_mult: @account_plan.sms_out_mult }
    assert_redirected_to account_plan_path(assigns(:account_plan))
  end

  test "should destroy account_plan" do
    assert_difference('AccountPlan.count', -1) do
      delete :destroy, id: @account_plan
    end

    assert_redirected_to account_plans_path
  end
end
