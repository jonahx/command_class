require 'rspec'
require_relative"../lib/command_class"

# Setup classes and collaborators to test
#
UserRepo = Class.new
MyEmailService = Class.new

module Errors
  class InvalidName < RuntimeError; end
  class InvalidEmail < RuntimeError; end
  class InvalidPassword < RuntimeError; end
  class EmailAlreadyExists < RuntimeError; end
end

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

# THE TESTS THEMSELVES
#
describe CommandClass do

  context "full CreateUser example" do
    let(:email_svc) { spy('email') }
    let(:user_repo) { spy('user_repo') }
    let(:valid_name) { 'John' }
    let(:valid_email) { 'john@gmail.com' }
    let(:valid_pw) { 'secret' }

    describe "happy path" do
      let(:happy_repo) do
        user_repo.tap do |x|
          allow(x).to receive(:find_by_email).and_return(nil)
        end
      end 

      subject(:create_user) do
        CreateUser.new(user_repo: happy_repo, email_service: email_svc)
      end

      it 'inserts the user into the db' do
        create_user.(name: valid_name, email: valid_email, password: valid_pw)
        expect(user_repo).to have_received(:insert)
      end

      it 'sends the confirmation email' do
        create_user.(name: valid_name, email: valid_email, password: valid_pw)
        expect(email_svc).to have_received(:send_signup_confirmation)
      end

    end

    describe "invalid user input" do
      subject(:create_user) do
        CreateUser.new(user_repo: user_repo, email_service: email_svc)
      end

      it 'errors for a short name' do
        expect do
          create_user.(name: 'x', email: valid_email, password: valid_pw)
        end.to raise_error(Errors::InvalidName)
      end

      it 'errors on an invalid email' do
        expect do
          create_user.(name: valid_email, email: 'bad_email', password: valid_pw)
        end.to raise_error(Errors::InvalidEmail)
      end
    end

    describe "existing email" do
      let(:repo_with_email) do
        user_repo.tap do |x|
          allow(x).to receive(:find_by_email).and_return('user obj')
        end
      end 

      subject(:create_user) do
        CreateUser.new(user_repo: repo_with_email, email_service: email_svc)
      end

      it 'errors' do
        expect do
          create_user.(name: valid_name, email: valid_email, password: valid_pw)
        end.to raise_error(Errors::EmailAlreadyExists)
      end
    end
  end

end
