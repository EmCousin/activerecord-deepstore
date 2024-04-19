# ActiveRecord-Deepstore

ActiveRecord-Deepstore is a Ruby gem that extends ActiveRecord models with additional functionality for handling deeply nested data structures within a database column. It simplifies storing, accessing, and managing complex nested data in your Rails applications.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activerecord-deepstore'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install activerecord-deepstore
```

## Usage

To use ActiveRecord-Deepstore in your Rails application, include it in your ActiveRecord models:

```ruby
class MyModel < ActiveRecord::Base
  extend ActiveRecord::Deepstore
end
```

Once included, your models gain access to methods for storing and accessing deeply nested data within database columns.

### Example

```ruby
class User < ActiveRecord::Base
  extend ActiveRecord::Deepstore

  deep_store :settings, {
    notifications: {
      posts: { push: true, email: true },
      comments: { push: true, email: false }
    }
  }
end
```

This implementation provides the following methods:

- `user.notifications_settings`
- `user.notifications_settings=`
- `user.posts_notifications_settings`
- `user.posts_notifications_settings=`
- `user.push_posts_notifications_settings`
- `user.push_posts_notifications_settings=`
- `user.email_posts_notifications_settings`
- `user.email_posts_notifications_settings=`
- `user.comments_notifications_settings`
- `user.comments_notifications_settings=`
- `user.push_comments_notifications_settings`
- `user.push_comments_notifications_settings=`
- `user.email_comments_notifications_settings`
- `user.email_comments_notifications_settings=`

Writer methods automatically cast the value to the type the default values belong to. For example:

```ruby
user.push_comments_notifications_settings = "1" # => "1"
user.push_comments_notifications_settings # => true
user.push_comments_notifications_settings = "0" # => "0"
user.push_comments_notifications_settings # => false
```

Dirty attributes are also implemented. For example:

```ruby
user.push_comments_notifications_settings # => false
user.push_comments_notifications_settings = true # => true
user.push_comments_notifications_settings_changes # => { false => true }
user.push_comments_notifications_settings_changed? # => true
```

Ensure that `ActiveSupport::HashWithIndifferentAccess` is allowed in Psych for the `accessor_name` to be serialized properly:

```ruby
Rails.application.config.active_record.yaml_column_permitted_classes = [
  ActiveSupport::HashWithIndifferentAccess
]
```

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/EmCousin/activerecord-deepstore](https://github.com/EmCousin/activerecord-deepstore).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
