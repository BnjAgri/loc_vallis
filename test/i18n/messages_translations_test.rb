# frozen_string_literal: true

require "test_helper"

class MessagesTranslationsTest < ActiveSupport::TestCase
  test "messages sender/composer/flash translations exist for fr and en" do
    %i[fr en].each do |locale|
      I18n.with_locale(locale) do
        keys = %w[
          messages.sender.traveler
          messages.sender.host
          messages.sender.me
          messages.composer.label
          messages.composer.placeholder
          messages.flash.not_sent
        ]

        keys.each do |key|
          refute_match(/^translation_missing:/, I18n.t(key), "Missing translation for #{locale}.#{key}")
        end
      end
    end
  end
end
