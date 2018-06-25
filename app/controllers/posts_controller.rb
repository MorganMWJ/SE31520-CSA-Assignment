class PostsController < ApplicationController

  def index
    #get all threads (highest level posts/posts that dont belong to any others)
    @threads = Post.where(thread: nil)
    #@my_post = Post.create
  end

end
