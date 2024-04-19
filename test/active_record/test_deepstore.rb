# frozen_string_literal: true

require "test_helper"
require "active_support"
require "active_record"

require_relative "../support/database_helper"

class User < ActiveRecord::Base
  extend ActiveRecord::Deepstore
end

module ActiveRecord
  class TestDeepstore < ActiveSupport::TestCase
    class VersionTest < self
      test "it has a version number" do
        refute_nil ::ActiveRecord::Deepstore::VERSION
      end
    end

    class DeepStoreTest < self
      setup do
        @settings_hash = { notifications: { email: false, push: true }, usage_count: 42 }

        DatabaseHelper.create_database("active_record_deepstore", adapter: ENV.fetch("DATABASE_ADAPTER", "postgresql"))
        unless ActiveRecord::Migration.table_exists? :users
          ActiveRecord::Migration.create_table :users do |t|
            t.string :name, null: false
            t.string :settings
          end
        end

        User.deep_store(:settings, @settings_hash) unless User.deep_stores.include?("settings")

        @emmanuel = User.create!(
          name: "Emmanuel",
          settings: @settings_hash
        )
      end

      teardown do
        ActiveRecord::Migration.drop_table(:users) if ActiveRecord::Migration.table_exists?(:users)
        DatabaseHelper.drop_database("active_record_deepstore_test")
      end

      test "reading deep store attributes through accessors" do
        assert_equal({ notifications: { email: false, push: true }, usage_count: 42 }.with_indifferent_access, @emmanuel.settings)
        assert_equal({ email: false, push: true }.with_indifferent_access, @emmanuel.notifications_settings)
        assert_equal false, @emmanuel.email_notifications_settings
        assert_equal true, @emmanuel.push_notifications_settings
        assert_equal 42, @emmanuel.usage_count_settings
      end

      test "writing store attributes through accessors" do
        @emmanuel.settings = { notifications: { email: true, push: false }, usage_count: 43 }
        assert_equal({ notifications: { email: true, push: false }, usage_count: 43 }.with_indifferent_access, @emmanuel.settings)
        assert_equal({ email: true, push: false }.with_indifferent_access, @emmanuel.notifications_settings)
        assert_equal true, @emmanuel.email_notifications_settings
        assert_equal false, @emmanuel.push_notifications_settings
        assert_equal 43, @emmanuel.usage_count_settings

        @emmanuel.notifications_settings = { email: false, push: true }
        assert_equal({ notifications: { email: false, push: true }, usage_count: 43 }.with_indifferent_access, @emmanuel.settings)
        assert_equal({ email: false, push: true }.with_indifferent_access, @emmanuel.notifications_settings)
        assert_equal false, @emmanuel.email_notifications_settings
        assert_equal true, @emmanuel.push_notifications_settings

        @emmanuel.email_notifications_settings = true
        assert_equal({ notifications: { email: true, push: true }, usage_count: 43 }.with_indifferent_access, @emmanuel.settings)
        assert_equal({ email: true, push: true }.with_indifferent_access, @emmanuel.notifications_settings)
        assert_equal true, @emmanuel.email_notifications_settings
        assert_equal true, @emmanuel.push_notifications_settings

        @emmanuel.push_notifications_settings = false
        assert_equal({ notifications: { email: true, push: false }, usage_count: 43 }.with_indifferent_access, @emmanuel.settings)
        assert_equal({ email: true, push: false }.with_indifferent_access, @emmanuel.notifications_settings)
        assert_equal true, @emmanuel.email_notifications_settings
        assert_equal false, @emmanuel.push_notifications_settings

        @emmanuel.usage_count_settings = 44
        assert_equal({ notifications: { email: true, push: false }, usage_count: 44 }.with_indifferent_access, @emmanuel.settings)
        assert_equal 44, @emmanuel.usage_count_settings
      end

      test "overriding a read accessor" do
        @emmanuel.settings[:notifications] = { email: true, push: false }
        assert_equal({ email: true, push: false }.with_indifferent_access, @emmanuel.notifications_settings)
        assert_equal true, @emmanuel.email_notifications_settings
        assert_equal false, @emmanuel.push_notifications_settings

        @emmanuel.settings[:notifications][:email] = false
        assert_equal({ email: false, push: false }.with_indifferent_access, @emmanuel.notifications_settings)
        assert_equal false, @emmanuel.email_notifications_settings
        assert_equal false, @emmanuel.push_notifications_settings

        @emmanuel.settings[:usage_count] = 43
        assert_equal 43, @emmanuel.usage_count_settings
      end

      test "updating the store will mark it as changed" do
        @emmanuel.push_notifications_settings = false

        assert_predicate @emmanuel, :settings_changed?
        assert_equal({ notifications: { email: false, push: true }, usage_count: 42 }.with_indifferent_access, @emmanuel.settings_was)
        assert_equal({ { notifications: { email: false, push: true }, usage_count: 42 }.with_indifferent_access => { notifications: { email: false, push: false }, usage_count: 42 }.with_indifferent_access }, @emmanuel.settings_changes)

        assert_predicate @emmanuel, :notifications_settings_changed?
        assert_equal({ email: false, push: true }.with_indifferent_access, @emmanuel.notifications_settings_was)
        assert_equal({ { email: false, push: true }.with_indifferent_access => { email: false, push: false }.with_indifferent_access }, @emmanuel.notifications_settings_changes)

        assert_predicate @emmanuel, :push_notifications_settings_changed?
        assert_equal true, @emmanuel.push_notifications_settings_was
        assert_equal({ true => false }, @emmanuel.push_notifications_settings_changes)

        refute_predicate @emmanuel, :usage_count_settings_changed?
      end

      test "automatically typecasting values for accessors" do
        @emmanuel.settings = { notifications: { email: "true", push: "false" }, usage_count: "43" }
        assert_equal({ notifications: { email: true, push: false }, usage_count: 43 }.with_indifferent_access, @emmanuel.settings)

        @emmanuel.email_notifications_settings = 0
        assert_equal false, @emmanuel.email_notifications_settings

        @emmanuel.email_notifications_settings = 1
        assert_equal true, @emmanuel.email_notifications_settings

        @emmanuel.email_notifications_settings = "false"
        assert_equal false, @emmanuel.email_notifications_settings

        @emmanuel.email_notifications_settings = "true"
        assert_equal true, @emmanuel.email_notifications_settings

        @emmanuel.email_notifications_settings = "truthy"
        assert_equal true, @emmanuel.email_notifications_settings

        @emmanuel.email_notifications_settings = nil
        assert_nil @emmanuel.email_notifications_settings

        @emmanuel.usage_count_settings = "10"
        assert_equal 10, @emmanuel.usage_count_settings

        @emmanuel.usage_count_settings = nil
        assert_nil @emmanuel.usage_count_settings

        @emmanuel.usage_count_settings = "invalid value"
        assert_equal 0, @emmanuel.usage_count_settings
      end
    end
  end
end
