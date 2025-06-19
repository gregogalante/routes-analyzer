class UsersController < ApplicationController
  def index
    render plain: "Users index"
  end

  def show
    render plain: "User #{params[:id]}"
  end

  def profile
    render plain: "User #{params[:id]} profile"
  end
end
