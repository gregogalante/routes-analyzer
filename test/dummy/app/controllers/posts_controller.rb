class PostsController < ApplicationController
  def index
    render plain: "Posts index"
  end

  def show
    render plain: "Post #{params[:id]}"
  end

  def create
    render plain: "Post created"
  end
end
