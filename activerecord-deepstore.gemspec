# frozen_string_literal: true

require_relative "lib/active_record/deepstore/version"

Gem::Specification.new do |spec|
  spec.name = "activerecord-deepstore"
  spec.version = ActiveRecord::Deepstore::VERSION
  spec.authors = ["Emmanuel Cousin"]
  spec.email = ["emmanuel@hey.com"]

  spec.summary = "ActiveRecord-Deepstore adds powerful functionality to ActiveRecord models for handling deeply nested data structures within database columns. Simplify storing, accessing, and managing complex nested data in your Rails applications with ease."
  spec.description = "ActiveRecord-Deepstore enhances ActiveRecord models with powerful functionality for handling deeply nested data structures within a database column. It provides methods for storing, accessing, and managing deeply nested data, making it easier to work with complex data structures in your Rails applications. With ActiveRecord-Deepstore, you can seamlessly store nested hashes in database columns, access nested data with simple method calls, track changes to nested attributes, and much more. This gem simplifies the handling of complex data structures, improving the maintainability and readability of your Rails codebase."
  spec.homepage = "https://github.com/EmCousin/activerecord-deepstore"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", "~> 7.0"
  spec.add_dependency "activesupport", "~> 7.0"
end
