class RelaysController < ApplicationController
  # GET /relays
  # GET /relays.xml
  def index
    @relays = Relay.all
    @pageTitle = "All Relays"

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @relays }
    end
  end

  # GET /relays/1
  # GET /relays/1.xml
  def show
    @relay = Relay.find(params[:id])
    @pageTitle = "Showing Relay: " + @relay.name

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @relay }
    end
  end

  # GET /relays/new
  # GET /relays/new.xml
  def new
    @users = User.find(params[:relay][:user_id])
    @relay = @users.relays.create(params[:relay])

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @relay }
    end
  end

  # GET /relays/1/edit
  def edit
    @relay = Relay.find(params[:id])
    @pageTitle = "Editing Relay: " + @relay.name
  end

  # POST /relays
  # POST /relays.xml
  def create
    @user = User.find(params[:relay][:user_id])
    @relay = @user.relays.create(params[:relay])

    respond_to do |format|
      if @relay.save
        format.html { redirect_to(@user, :notice => 'Relay was successfully created.') }
        format.xml  { render :xml => @relay, :status => :created, :location => @relay }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @relay.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /relays/1
  # PUT /relays/1.xml
  def update
    @relay = Relay.find(params[:id])

    respond_to do |format|
      if @relay.update_attributes(params[:relay])
        format.html { redirect_to(@relay, :notice => 'Relay was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @relay.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /relays/1
  # DELETE /relays/1.xml
  def destroy
    @relay = Relay.find(params[:id])
    @user = @relay.user
    @relay.destroy

    respond_to do |format|
      format.html { redirect_to(user_path(@user)) }
      format.xml  { head :ok }
    end
  end
end
