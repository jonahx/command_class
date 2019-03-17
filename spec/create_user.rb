# This example shows how to create a CommandClass using: 
#
#     extend CommandClass::Include  
#
# This allows you to use ordinary ruby class syntax and add custom error
# classes withing the class body.
#
# See CreateUser2 for an alternate syntax, which has the disadvantage of not
# allowing this.

require_relative './user_repo'
require_relative './my_email_service'

class CreateUser 
  extend CommandClass::Include

  class InvalidName < RuntimeError; end
  class InvalidEmail < RuntimeError; end
  class InvalidPassword < RuntimeError; end
  class EmailAlreadyExists < RuntimeError; end

  command_class(
    dependencies: {user_repo: UserRepo, email_service: MyEmailService},
    inputs: %i[name email password]
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
      raise EmailAlreadyExists if email_exists
    end

    def insert_user
      @user_repo.insert(name: @name, email: @email, password: @password)
    end

    def send_confirmation
      @email_service.send_signup_confirmation(name: @name, email: @email)
    end

    def validate_name
      valid = @name.size > 1
      raise InvalidName unless valid
    end

    def validate_email
      valid = @email =~ /@/
      raise InvalidEmail unless valid
    end

    def validate_password
      valid = @password.size > 5
      raise InvalidPassword unless valid
    end

  end
end
