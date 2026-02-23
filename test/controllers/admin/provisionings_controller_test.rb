require "test_helper"

module Admin
  class ProvisioningsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @owner = Owner.create!(email: "owner_provisioning@test.local", password: "password")
    end

    test "returns 404 when provisioning UI is disabled" do
      begin
        previous = ENV["PROVISIONING_UI_ENABLED"]
        ENV["PROVISIONING_UI_ENABLED"] = "false"

        sign_in @owner
        get admin_provisioning_path
        assert_response :not_found
      ensure
        ENV["PROVISIONING_UI_ENABLED"] = previous
      end
    end

    test "shows page when provisioning UI is enabled" do
      begin
        previous = ENV["PROVISIONING_UI_ENABLED"]
        ENV["PROVISIONING_UI_ENABLED"] = "true"

        sign_in @owner
        get admin_provisioning_path
        assert_response :success
        assert_includes response.body, "Provisioning (dev)"
      ensure
        ENV["PROVISIONING_UI_ENABLED"] = previous
      end
    end

    test "generates a command on POST" do
      begin
        previous = ENV["PROVISIONING_UI_ENABLED"]
        ENV["PROVISIONING_UI_ENABLED"] = "true"

        sign_in @owner
        post admin_provisioning_path, params: {
          provisioning: {
            heroku_app: "lv-test",
            client_domain: "booking.example.test",
            stripe_secret_key: "sk_test_123",
            mail_from: "no-reply@example.test",
            create_app: "1",
            add_domain: "1",
            scale: "1",
            db_prepare: "1"
          }
        }

        assert_response :success
        assert_includes response.body, "./script/provision_client.sh"
        assert_includes response.body, "HEROKU_APP=lv-test"
        assert_includes response.body, "CLIENT_DOMAIN=booking.example.test"
      ensure
        ENV["PROVISIONING_UI_ENABLED"] = previous
      end
    end
  end
end
