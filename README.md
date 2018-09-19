# Install

```
gem install command_class
```

# Example Use

1. Define your command object class.  This is a longish but real-worldish example:

```ruby
CreateUser = CommandClass.new(
  dependencies: {user_repo: UserRepo, email_service: MyEmailService},
  inputs: [:name, :email, :password]
) do

  def call
    validate_input
    ensure_unique_email
    insert_user
    send_confirmation
  end

  private

  def validate_input
    validate_name
    validate_email
    validate_password
  end

  def ensure_unique_email
    email_exists = @user_repo.find_by_email(@email)
    raise Errors::EmailAlreadyExists if email_exists
  end

  def insert_user
    @user_repo.insert(name: @name, email: @email, password: @password)
  end

  def send_confirmation
    @email_service.send_signup_confirmation(name: @name, email: @email)
  end

  def validate_name
    valid = @name.size > 1
    raise Errors::InvalidName unless valid
  end

  def validate_email
    valid = @email =~ /@/
    raise Errors::InvalidEmail unless valid
  end

  def validate_password
    valid = @password.size > 5
    raise Errors::InvalidPassword unless valid
  end

end
```

2. Create your command object itself:

```ruby
create_user = CreateUser.new
```
**NOTE:** Here, alternatively, we can inject dependencies other than the default ones, which vastly improves tests.  See the specs for examples of this.

3. Run the command object:

```ruby
create_user.(name: valid_name, email: valid_email, password: valid_pw)
```

# Motivation

On the benefits of Functional Command Objects:

https://www.icelab.com.au/notes/functional-command-objects-in-ruby/

For a more complex, but also more fully-featured version of this idea, see:

https://dry-rb.org/gems/dry-transaction/

More to come...
