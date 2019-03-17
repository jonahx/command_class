require 'rspec'
require_relative '../lib/command_class'
require_relative './create_user2'

describe CommandClass do

  context "Full CreateUser2 example using legacy syntax" do
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
        CreateUser2.new(user_repo: happy_repo, email_service: email_svc)
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
        CreateUser2.new(user_repo: user_repo, email_service: email_svc)
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
        CreateUser2.new(user_repo: repo_with_email, email_service: email_svc)
      end

      it 'errors' do
        expect do
          create_user.(name: valid_name, email: valid_email, password: valid_pw)
        end.to raise_error(Errors::EmailAlreadyExists)
      end
    end
  end

end
