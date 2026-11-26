require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "new" do
    get new_registration_path

    assert_response :success
    assert_select "h1", "Crear una cuenta"
  end

  test "create signs the new user in" do
    assert_difference "User.count", 1 do
      post registration_path, params: { user: { email_address: "Nuevo@Example.com", password: "long-enough-secret", password_confirmation: "long-enough-secret" } }
    end

    assert_redirected_to root_path
    assert cookies[:session_id]
    assert_equal "nuevo@example.com", User.last.email_address
  end

  test "create renders errors for invalid data" do
    assert_no_difference "User.count" do
      post registration_path, params: { user: { email_address: "one@example.com", password: "short", password_confirmation: "other" } }
    end

    assert_response :unprocessable_content
    assert_select ".form-errors li", minimum: 2
    assert_nil cookies[:session_id]
  end

  test "create rejects requests without the user payload" do
    post registration_path, params: { email_address: "nuevo@example.com" }

    assert_response :bad_request
  end
end
