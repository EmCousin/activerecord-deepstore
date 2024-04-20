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

This implementation provides with an accessor for every level of the provider hash:

```ruby
user.notifications_settings # => { posts: { push: true, email: true }, comments: { push: true, email: false } }
user.posts_notifications_settings # => { push: true, email: true }
user.push_posts_notifications_settings # => true
user.email_posts_notifications_settings # => true
user.comments_notifications_settings # => { push: true, email: false }
user.push_comments_notifications_settings # => true
user.email_comments_notifications_settings # => false
```

#### Automatic typecasting

Writer methods automatically cast the value to the type the default values belong to. For example:

```ruby
user.push_comments_notifications_settings = "1" # => "1"
user.push_comments_notifications_settings # => true
user.push_comments_notifications_settings = "0" # => "0"
user.push_comments_notifications_settings # => false
```

#### Tracking value changes

Dirty attributes are implemented for every accessor. For example:

```ruby
user.push_comments_notifications_settings # => false
user.push_comments_notifications_settings = true # => true
user.push_comments_notifications_settings_was # => false
user.push_comments_notifications_settings_changes # => { false => true }
user.push_comments_notifications_settings_changed? # => true
```

#### Accessing default values

You can access the default value of every accessor at anytime by calling the associated `default_#{accessor_name}` method:

```ruby
user.push_comments_notifications_settings # => false
user.update! push_comments_notifications_settings: true
user.push_comments_notifications_settings # => true
user.default_push_comments_notifications_settings #=> false
```

#### Resetting to default values

You can reset every accessor to its default value  at anytime by calling the associated `reset_#{accessor_name}` method:

```ruby
# When the changes are not persisted
user.push_comments_notifications_settings # => false
user.push_comments_notifications_settings = true
user.reset_push_comments_notifications_settings
user.push_comments_notifications_settings # => false

# When the changes are persisted
user.update! push_comments_notifications_settings: true
user.push_comments_notifications_settings # => true
user.reset_push_comments_notifications_settings!
user.reload.push_comments_notifications_settings # => false
```

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/EmCousin/activerecord-deepstore](https://github.com/EmCousin/activerecord-deepstore).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
