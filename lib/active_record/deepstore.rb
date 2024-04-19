# frozen_string_literal: true

require_relative "deepstore/version"

module ActiveRecord
  # The ActiveRecord::Deepstore module extends ActiveRecord models with additional
  # functionality for handling deeply nested data structures within a database column.
  module Deepstore
    # Raised when an error occurs in the ActiveRecord::Deepstore module.
    class Error < StandardError; end

    # Retrieves or initializes the array containing names of attributes declared as deep stores.
    #
    # @return [Array<String>] The array containing names of deep stores.
    def deep_stores
      @deep_stores ||= []
    end

    # Recursively traverses a nested hash and returns a flattened representation of leaf nodes along with their paths.
    #
    # @param hash [Hash] The nested hash to traverse.
    # @param path [Array] The current path in the hash.
    # @param current_depth [Integer] The current depth in the hash traversal.
    # @param max_depth [Integer, nil] The maximum depth to traverse. If nil, traverses the entire hash.
    # @return [Hash] The flattened representation of leaf nodes along with their paths.
    def leaves(hash, path: [], current_depth: 0, max_depth: nil)
      hash.each_with_object({}) do |(key, value), result|
        current_path = path + [key]

        if value.is_a?(Hash) && (max_depth.nil? || current_depth < max_depth)
          result.merge!(leaves(value, path: current_path, current_depth: current_depth + 1, max_depth: max_depth))
        else
          result[current_path] = value
        end
      end
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/PerceivedComplexity

    # Defines behavior for storing deeply nested data in a database column.
    #
    # @param accessor_name [Symbol, String] The name of the accessor for the deep store.
    # @param payload [Hash] The hash representing the deeply nested data.
    # @param suffix [Boolean] Whether to include a suffix in the accessor name.
    # @param column_required [Boolean] Whether the corresponding column is required in the database table.
    # @raise [ActiveRecord::Deepstore::Error] If the deep store is already declared.
    # @raise [NotImplementedError] If the required column is not found in the database table.
    # @return [void]
    def deep_store(accessor_name, payload, suffix: true, column_required: true)
      accessor_name = accessor_name.to_s.parameterize.underscore

      raise Error, "Deep store '#{accessor_name}' is already declared" if @deep_stores.include?(accessor_name)

      @deep_stores << accessor_name

      if column_required && (columns.find do |c|
                               c.name == accessor_name.to_s
                             end).blank?
        raise NotImplementedError,
              "Column #{accessor_name} not found for table #{table_name}"
      end

      serialize accessor_name, type: Hash, default: payload, yaml: { unsafe_load: true } if payload.is_a?(Hash)

      define_method(:"default_#{accessor_name}") { payload.try(:with_indifferent_access) || payload }

      define_method(:"reset_#{accessor_name}!") { update(accessor_name => payload) }

      define_method(:"#{accessor_name}_changes") do
        old_value = send(:"#{accessor_name}_was")
        current_value = send(accessor_name)
        old_value == current_value ? {} : { old_value => current_value }
      end

      define_method(:"#{accessor_name}=") do |value|
        old_value = send(:"#{accessor_name}_was")

        if value.is_a?(Hash)
          value = {}.with_indifferent_access if value.blank?
          self.class.leaves(value).each do |leaf_path, leaf_value|
            default_value = leaf_path.inject(payload.with_indifferent_access) do |h, key|
              h.is_a?(Hash) ? h.fetch(key, h) : h
            end
            cast_type = self.class.cast_type_from_name(self.class.cast_type_name_from_value(default_value))

            # Traverse the hash using the leaf path and update the leaf value.
            leaf_key = leaf_path.pop
            parent_hash = leaf_path.inject(value, :[])
            #  old_leaf_value = parent_hash[leaf_key]
            new_leaf_value = cast_type.cast(leaf_value)
            old_parent_hash = parent_hash.dup
            parent_hash[leaf_key] = new_leaf_value

            instance_variable_set(:"@#{leaf_path.join("_")}_#{accessor_name}_was",
                                  old_parent_hash.with_indifferent_access)
          end

          formatted_value = payload.with_indifferent_access.deep_merge(value)
        else
          default_value = send(:"default_#{accessor_name}")
          cast_type = self.class.cast_type_from_name(self.class.cast_type_name_from_value(default_value))
          formatted_value = cast_type.cast(value)
        end

        instance_variable_set(:"@#{accessor_name}_was", old_value)

        super(formatted_value)
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/PerceivedComplexity

      return unless payload.is_a?(Hash)

      payload.each do |key, value|
        deep_store_accessor(accessor_name, payload, key, value, suffix)
      end
    end

    # Reloads the model instance and clears deep store changes information.
    #
    # @param args [Array] Arguments to pass to the reload method.
    # @return [void]
    define_method(:reload) do |*args|
      clear_deep_store_changes_information
      super(*args)
    end

    # Clears deep store changes information.
    #
    # @return [void]
    define_method(:clear_deep_store_changes_information) do
      self.class.deep_stored_accessors.each do |accessor|
        formatted_accessor = accessor.to_s.parameterize.underscore
        instance_variable_set(:"@#{formatted_accessor}_was", send(formatted_accessor))
      end
    end

    # Defines accessor methods for nested keys within the deep store hash.
    #
    # @param accessor_name [Symbol, String] The name of the deep store accessor.
    # @param payload [Hash] The hash representing the deeply nested data.
    # @param key [Symbol, String] The key within the hash.
    # @param value [Object] The value associated with the key.
    # @param suffix [Boolean] Whether to include a suffix in the accessor name.
    # @return [void]
    def deep_store_accessor(accessor_name, payload, key, value, suffix)
      store_json_accessor(accessor_name, payload, key, suffix)

      deep_store(deep_accessor_name(accessor_name, key), value, column_required: false)

      return if value.is_a?(Hash)

      define_method(deep_accessor_name(accessor_name, key)) do
        return value unless (hash = public_send(accessor_name)).is_a?(Hash) && hash.key?(key)

        hash[key]
      end
    end

    # rubocop:disable Metrics/MethodLength

    # Defines accessor methods for individual keys within the nested hash.
    #
    # @param accessor_name [Symbol, String] The name of the deep store accessor.
    # @param hash [Hash] The hash representing the deeply nested data.
    # @param key [Symbol, String] The key within the hash.
    # @param suffix [Boolean] Whether to include a suffix in the accessor name.
    # @return [void]
    def store_json_accessor(accessor_name, hash, key, suffix)
      store_accessor(accessor_name.to_sym, key, suffix: suffix)
      base_method_name = deep_accessor_name(accessor_name, key)
      @deep_stored_accessors ||= []
      @deep_stored_accessors << base_method_name
      attribute base_method_name, cast_type_name_from_value(hash[key])

      define_method(:"#{base_method_name}_was") do
        method_name = :"#{base_method_name}_was"
        return instance_variable_get("@#{method_name}") if instance_variable_defined?("@#{method_name}")

        instance_variable_set("@#{method_name}", send(base_method_name))
      end

      define_method(:"#{base_method_name}_changed?") do
        send(:"#{base_method_name}_changes").any?
      end
    end
    # rubocop:enable Metrics/MethodLength

    # Generates a unique name for accessor methods based on the accessor name and key.
    #
    # @param accessor_name [Symbol, String] The name of the deep store accessor.
    # @param key [Symbol, String] The key within the hash.
    # @return [String] The generated accessor name.
    def deep_accessor_name(accessor_name, key)
      "#{key.to_s.parameterize.underscore}_#{accessor_name.to_s.parameterize.underscore}"
    end

    # Determines the data type for serialization based on the value type.
    #
    # @param name [Symbol, String] The name of the data type.
    # @return [ActiveRecord::Type::Value] The corresponding data type.
    def cast_type_from_name(name)
      ActiveRecord::Type.lookup name.to_sym, adapter: ActiveRecord::Type.adapter_name_from(self)
    end

    # Determines the data type name based on the value.
    #
    # @param value [Object] The value for which to determine the data type name.
    # @return [Symbol] The name of the data type.
    def cast_type_name_from_value(value)
      type_mappings = {
        TrueClass => :boolean,
        FalseClass => :boolean,
        NilClass => :string,
        Hash => :text
      }

      type_mappings.fetch(value.class, value.class.name.underscore.to_sym)
    end
  end
end
