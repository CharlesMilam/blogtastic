require 'sinatra'
require 'sinatra/reloader'
require 'pry-byebug'
require 'rack-flash'

require_relative 'lib/blogtastic.rb'

class Blogtastic::Server < Sinatra::Application
  configure do
    enable :sessions
    use Rack::Flash
  end

  before do
    if session['user_id']
      user_id = session['user_id']
      db = Blogtastic.create_db_connection 'blogtastic'
      @current_user = Blogtastic::UsersRepo.find db, user_id
    else
      @current_user = {'username' => 'anonymous', 'id' => 1}
    end
  end



  ###################################################################
  # DO NOT EDIT ANYTHING ABOVE THIS AREA
  ###################################################################

  # Refer to `lib/blogtastic/repos/users_repo.rb` to see how you can
  # save and find users to handle the authentication process.

  get '/signup' do
    # DONE: render template with form for user to sign up
    erb :"/auth/signup"
  end

  post '/signup' do
    # DONE: save user's info to db and create session
    # Create the session by adding a new key value pair to the
    # session hash. The key should be 'user_id' and the value
    # should be the user id of the user who was just created.
    db = Blogtastic.create_db_connection 'blogtastic'
    @user_name = params["user_name"]
    @user_pwd = params["user_pwd"]
    
    result = Blogtastic::UsersRepo.save db, :username => @user_name, :password => @user_pwd
    
    if result
      signin = Blogtastic::UsersRepo.find db, result["id"].to_i
      if signin
        session["user_id"] = signin["id"]
        puts session
        redirect "/posts"
      end
    else
      alert("Signup did not complete properly. Please try again.")
      redirect back
    end
  end

  get '/signin' do
    # DONE: render template for user to sign in
    erb :"/auth/signin"
  end

  post '/signin' do
    # TODO: validate users credentials and create session
    # Create the session by adding a new key value pair to the
    # session hash. The key should be 'user_id' and the value
    # should be the user id of the user who just logged in.
    db = Blogtastic.create_db_connection 'blogtastic'
    @user_name = params["user_name"]
    @user_pwd = params["user_pwd"]

    signin = Blogtastic::UsersRepo.find_by_name db, @user_name
    if @user_pwd == signin["password"]
      session["user_id"] = signin["id"]
      puts session
      redirect "/posts"
    else
      alert("Signup did not complete properly. Please try again.")
      redirect back
    end

  end

  get '/logout' do
    # DONE: destroy the session
    # TODO: not have to click twice on logout to actually logout
    session["user_id"] = 1
    erb :"/auth/logout"
  end

  ###################################################################
  # DO NOT EDIT ANYTHING BELOW THIS AREA
  ###################################################################



  # landing
  get '/' do
    erb :index
  end

  # view all posts
  get '/posts' do
    db = Blogtastic.create_db_connection 'blogtastic'
    @posts = Blogtastic::PostsRepo.all db
    erb :'posts/index'
  end

  # new post page
  get '/posts/new' do
    erb :'posts/new'
  end

  # create a new post
  post '/posts' do
    post = {
      title:   params[:title],
      content: params[:content],
      user_id:    params[:user_id]
    }
    db = Blogtastic.create_db_connection 'blogtastic'
    Blogtastic::PostsRepo.save db, post

    redirect to '/posts'
  end

  # view a particular post
  get '/posts/:id' do
    db = Blogtastic.create_db_connection 'blogtastic'
    @post = Blogtastic::PostsRepo.find db, params[:id]
    @comments = Blogtastic::CommentsRepo.post_comments db, params[:id]
    @user = Blogtastic::UsersRepo.find db, @post['user_id']

    @comments.map do |c|
      comment_user = Blogtastic::UsersRepo.find db, c['user_id']
      c['user'] = comment_user['username']
    end

    erb :'posts/post'
  end

  # create a new comment on a post
  post '/posts/:post_id/comments' do
    comment = {
      content: params[:content],
      user_id: params[:user_id],
      post_id: params[:post_id]
    }
    db = Blogtastic.create_db_connection 'blogtastic'
    Blogtastic::CommentsRepo.save db, comment
    redirect to '/posts/' + params[:post_id]
  end

  # delete a post
  delete '/posts/:id' do
    db = Blogtastic.create_db_connection 'blogtastic'
    Blogtastic::PostsRepo.destroy db, params[:id]
    redirect to '/posts'
  end
end
