class ExtServicesController < ApplicationController
  before_action :set_ext_service, only: [:show, :edit, :update, :destroy]
  before_filter :ensure_admin!

  respond_to :html

  def index
    @ext_services = ExtService.all
    respond_with(@ext_services)
  end

  def show
    respond_with(@ext_service)
  end

  def new
    @ext_service = ExtService.new
    respond_with(@ext_service)
  end

  def edit
  end

  def create
    @ext_service = ExtService.new(ext_service_params)
    @ext_service.save
    respond_with(@ext_service)
  end

  def update
    @ext_service.update(ext_service_params)
    respond_with(@ext_service)
  end

  def destroy
    @ext_service.destroy
    respond_with(@ext_service)
  end

  private

    def ensure_admin!
      render_401 unless @current_user && @current_user.admin?
    end

    def set_ext_service
      @ext_service = ExtService.find(params[:id])
    end

    def ext_service_params
      params.require(:ext_service).permit(:social_net_id, :consumer_id, :consumer_type)
    end
end
