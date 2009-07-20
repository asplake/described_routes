class UsersController < ApplicationController
  def index
    render :text => "<h1>index</h1>", :layout => true
  end

  def new
    render :text => "<h1>new</h1>", :layout => true
  end

  def show
    render :text => "<h1>show #{params[:id]}</h1>", :layout => true
  end
  
  def edit
    render :text => "<h1>edit #{params[:id]}</h1>", :layout => true
  end
end
