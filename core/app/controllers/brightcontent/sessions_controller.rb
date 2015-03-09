require_dependency "brightcontent/application_controller"

module Brightcontent
  class SessionsController < ApplicationController
    skip_before_filter :authorize

    def new
      redirect_to root_url if current_user
    end

    def create
      user = Brightcontent.user_model.authenticate(params[:email], params[:password])
      if user
        session[:brightcontent_user_id] = user.id
        redirect_to root_url
      else
        flash.now[:danger] = "Email or password is invalid"
        render :new
      end
    end

    def destroy
      session[:brightcontent_user_id] = nil
      redirect_to root_url
    end
  end
end
