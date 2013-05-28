class AuthenticationsController < ApplicationController
  # GET /authentications
  # GET /authentications.json
  def index
    @authentications = current_user.authentications if current_user

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @authentications }
    end
  end

  # GET /authentications/1
  # GET /authentications/1.json
  def show
    @authentication = Authentication.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @authentication }
    end
  end

  # GET /authentications/new
  # GET /authentications/new.json
  def new
    @authentication = Authentication.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @authentication }
    end
  end

  # GET /authentications/1/edit
  def edit
    @authentication = Authentication.find(params[:id])
  end

  # POST /authentications
  # POST /authentications.json
  def create

    omniauth =  request.env["omniauth.auth"] 
    authentication = Authentication.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])

    #authentication.update_attributes( :token => omniauth["credentials"]["token"] )

    if authentication && authentication.user.present?
      flash[ :notice] = "Sign in by Facebook Successfull"
      @user = User.find(authentication.user_id)
      #get_fb_info(@user.id)
      sign_in_and_redirect( :user, @user)

    elsif current_user
      current_user.authentications.create!( :provider => omniauth['provider'], :uid => omniauth['uid'])
      get_fb_info(current_user.id)
      flash[:notice] = "Authentication successful."
      redirect_to authentications_url

    else
      user = User.new
      user.apply_omniauth(omniauth)
      user.save
      if user.save
        flash[ :notice] = "Sign up and Sign in by Facebook Successfull"
        #get_fb_info(user.id)
        sign_in_and_redirect( :user, user)
        get_fb_info(user.id)
      else
        session[ :omniauth] = omniauth.except('extra')
        redirect_to new_user_registration_url
      end
    end
  end

  # PUT /authentications/1
  # PUT /authentications/1.json
  def update
    @authentication = Authentication.find(params[:id])

    respond_to do |format|
      if @authentication.update_attributes(params[:authentication])
        format.html { redirect_to @authentication, notice: 'Authentication was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @authentication.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /authentications/1
  # DELETE /authentications/1.json
  def destroy
    @authentication = current_user.authentications.find(params[:id])
    @authentication.destroy

    respond_to do |format|
      format.html { redirect_to authentications_url }
      format.json { head :no_content }
    end
  end
end
