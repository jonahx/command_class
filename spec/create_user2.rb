# This example shows how to create a CommandClass directly using
# `CommandClass.new`.
#
# Note how we are force in this case to define our Errors outside the
# CommandClass itself, which is typically *not* what we want.  
#
# For a more flexible alternative that allows you to use ordinary ruby class
# syntax and add custom error classes withing the class body, see
# create_user.rb.

require_relative './user_repo'
require_relative './my_email_service'

module Errors
  class InvalidName < RuntimeError; end
  class InvalidEmail < RuntimeError; end
  class InvalidPassword < RuntimeError; end
  class EmailAlreadyExists < RuntimeError; end
end

CreateUser2 = CommandClass.new(
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
