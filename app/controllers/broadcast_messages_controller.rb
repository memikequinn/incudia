class BroadcastMessagesController < ApplicationController
  before_action :require_admin!
  before_action :set_broadcast_message, only: [:show, :edit, :update, :destroy]

  respond_to :html, :json

  def index
    @broadcast_messages = BroadcastMessage.all
    respond_with(@broadcast_messages)
  end

  def show
    respond_with(@broadcast_message)
  end

  def new
    @broadcast_message = BroadcastMessage.new
    respond_with(@broadcast_message)
  end

  def edit
  end

  def create
    @broadcast_message = BroadcastMessage.new(broadcast_message_params)
    respond_with(@broadcast_message) do |format|
      if @broadcast_message.save
        format.json { render head: :ok, status: :created }
        format.html{ render @broadcast_message, status: 201}
      else
        flash[:error] = @broadcast_message.errors.to_s
        format.html { render :action => :new }
      end
    end

  end

  def update
    @broadcast_message.update(broadcast_message_params)
    respond_with(@broadcast_message)
  end

  def destroy
    @broadcast_message.destroy
    respond_with(@broadcast_message)
  end

  private
  def set_broadcast_message
    @broadcast_message = BroadcastMessage.find(params[:id])
  end

  def broadcast_message_params
    params.require(:broadcast_message).permit(:message, :ends_at, :starts_at, :alert_type, :color, :font)
  end
end
