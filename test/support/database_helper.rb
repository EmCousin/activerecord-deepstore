# frozen_string_literal: true

# Define a module for database setup and teardown
module DatabaseHelper
  extend self

  def create_database(database_name, adapter: "postgresql")
    ActiveRecord::Base.establish_connection(default_connection(adapter: adapter))

    return if adapter == "sqlite3"

    ActiveRecord::Base.connection.create_database(database_name) unless ActiveRecord::Base.connection.database_exists?
  end

  def drop_database(database_name, adapter: "postgresql")
    ActiveRecord::Base.establish_connection(default_connection(adapter: adapter))
    return if adapter == "sqlite3"

    ActiveRecord::Base.connection.drop_database(database_name) if ActiveRecord::Base.connection.database_exists?
  end

  private

  def default_connection(adapter: "postgresql")
    case adapter
    when "postgresql" then POSTGRES_CONNECTION
    when "sqlite3" then SQLITE_CONNECTION
    end
  end

  POSTGRES_CONNECTION = {
    adapter: "postgresql",
    username: ENV.fetch("PGUSER", "postgres"),
    password: ENV.fetch("PGPASSWORD", ""),
    host: ENV.fetch("PGHOST", "localhost"),
    port: 5432
  }.freeze

  SQLITE_CONNECTION = {
    adapter: "sqlite3",
    database: "db/activerecord-deepstore.sqlite3",
    pool: 5,
    timeout: 5000
  }.freeze
end
