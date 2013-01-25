require 'test_helper'

class LedgerEntriesControllerTest < ActionController::TestCase
  setup do
    @ledger_entry = ledger_entries(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:ledger_entries)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create ledger_entry" do
    assert_difference('LedgerEntry.count') do
      post :create, ledger_entry: { item: @ledger_entry.item, narrative: @ledger_entry.narrative, value: @ledger_entry.value }
    end

    assert_redirected_to ledger_entry_path(assigns(:ledger_entry))
  end

  test "should show ledger_entry" do
    get :show, id: @ledger_entry
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @ledger_entry
    assert_response :success
  end

  test "should update ledger_entry" do
    put :update, id: @ledger_entry, ledger_entry: { item: @ledger_entry.item, narrative: @ledger_entry.narrative, value: @ledger_entry.value }
    assert_redirected_to ledger_entry_path(assigns(:ledger_entry))
  end

  test "should destroy ledger_entry" do
    assert_difference('LedgerEntry.count', -1) do
      delete :destroy, id: @ledger_entry
    end

    assert_redirected_to ledger_entries_path
  end
end
