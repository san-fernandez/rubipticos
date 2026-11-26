# frozen_string_literal: true

# ABM de usuarios del backend (solo admin: lo exige Admin::BaseController).
# No hay destroy: un usuario se desactiva (update de active), porque los
# SyncLog guardan qué admin sincronizó. Las reglas (último admin, no
# desactivarse a uno mismo, cerrar sesiones) están en el modelo User.
class Admin::UsersController < Admin::BaseController
  PER_PAGE = 20

  before_action :set_user, only: %i[edit update]

  def index
    @users = User.order(:email_address).page(params[:page]).per(PER_PAGE)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(params.expect(user: %i[email_address password password_confirmation role]))

    if @user.save
      redirect_to admin_users_path, notice: "Usuario #{@user.email_address} creado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(update_params)
      redirect_to admin_users_path, notice: "Usuario #{@user.email_address} actualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  # La contraseña es opcional al editar: si viene vacía, no se cambia.
  def update_params
    attributes = params.expect(user: %i[email_address password password_confirmation role active])
    attributes[:password].blank? ? attributes.except(:password, :password_confirmation) : attributes
  end
end
