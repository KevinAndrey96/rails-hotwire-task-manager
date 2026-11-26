class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 5, within: 10.minutes, only: :create,
    with: -> { redirect_to new_registration_path, alert: t("registrations.rate_limited") }

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)

    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: t(".welcome")
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def registration_params
      params.expect(user: %i[email_address password password_confirmation])
    end
end
