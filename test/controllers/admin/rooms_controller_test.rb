require "test_helper"
require "action_dispatch/testing/test_process"

module Admin
  class RoomsControllerTest < ActionDispatch::IntegrationTest
    include ActionDispatch::TestProcess

    test "update does not wipe photos when no new upload is selected" do
      owner = Owner.create!(
        email: "owner_room_update_photos@example.com",
        password: "password123",
        first_name: "Claude",
        last_name: "Owner"
      )

      room = Room.create!(
        owner:,
        name: "Chambre test",
        capacity: 2,
        room_url: "https://res.cloudinary.com/demo/image/upload/sample.jpg"
      )

      room.photos.attach(fixture_file_upload("dummy.png", "image/png"))
      assert room.photos.attached?

      sign_in owner

      patch admin_room_path(id: room), params: {
        room: {
          name: "Chambre test (maj)",
          # This mimics the browser submitting an empty multi-file field.
          photos: [""],
          room_url: ""
        }
      }

      assert_redirected_to admin_room_path(id: room)

      room.reload
      assert room.photos.attached?, "Expected existing photos to remain attached"
      assert_equal "https://res.cloudinary.com/demo/image/upload/sample.jpg", room.room_url
    end

    test "destroy_photo removes a single attached photo" do
      owner = Owner.create!(
        email: "owner_room_delete_photo@example.com",
        password: "password123",
        first_name: "Claude",
        last_name: "Owner"
      )

      room = Room.create!(owner:, name: "Chambre test", capacity: 2)
      room.photos.attach(fixture_file_upload("dummy.png", "image/png"))
      attachment_id = room.photos.first.id
      assert room.photos.attached?

      sign_in owner

      assert_difference("ActiveStorage::Attachment.count", -1) do
        delete photo_admin_room_path(id: room, photo_id: attachment_id)
      end

      assert_redirected_to edit_admin_room_path(id: room)
      room.reload
      assert_not room.photos.attached?
    end

    test "destroy is blocked when room has upcoming requested booking" do
      owner = Owner.create!(
        email: "owner_destroy_block@example.com",
        password: "password123",
        first_name: "Claude",
        last_name: "Owner"
      )

      user = User.create!(
        email: "user_destroy_block@example.com",
        password: "password123",
        first_name: "Jean",
        last_name: "User"
      )

      room = Room.create!(owner:, name: "Chambre test", capacity: 2)

      OpeningPeriod.create!(
        room:,
        start_date: Date.current + 10,
        end_date: Date.current + 15,
        nightly_price_cents: 10_00,
        currency: "EUR"
      )

      Booking.create!(
        room:,
        user:,
        start_date: Date.current + 10,
        end_date: Date.current + 12,
        status: "requested"
      )

      sign_in owner

      assert_no_difference("Room.count") do
        delete admin_room_path(id: room)
      end

      assert_redirected_to admin_room_path(id: room)
      assert_equal "Réservations à venir, suppression impossible", flash[:alert]
    end

    test "destroy is allowed when room has only non-blocking bookings" do
      owner = Owner.create!(
        email: "owner_destroy_allowed@example.com",
        password: "password123",
        first_name: "Claude",
        last_name: "Owner"
      )

      user = User.create!(
        email: "user_destroy_allowed@example.com",
        password: "password123",
        first_name: "Jean",
        last_name: "User"
      )

      room = Room.create!(owner:, name: "Chambre test 2", capacity: 2)

      OpeningPeriod.create!(
        room:,
        start_date: Date.current + 10,
        end_date: Date.current + 15,
        nightly_price_cents: 10_00,
        currency: "EUR"
      )

      Booking.create!(
        room:,
        user:,
        start_date: Date.current + 10,
        end_date: Date.current + 12,
        status: "canceled"
      )

      sign_in owner

      assert_difference("Room.count", -1) do
        delete admin_room_path(id: room)
      end

      assert_redirected_to admin_rooms_path
    end
  end
end
