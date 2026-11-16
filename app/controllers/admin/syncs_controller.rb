# frozen_string_literal: true

# Sincronización del catálogo (solo admin). La lógica está en CrypticSynchronizer:
# el controlador solo lo llama y muestra el resultado.
class Admin::SyncsController < Admin::BaseController
  PER_PAGE = 15

  def index
    @source_url = Setting.current.source_url
    @last_sync = SyncLog.recent.first
    @sync_logs = SyncLog.recent.includes(:user).page(params[:page]).per(PER_PAGE)
  end

  def create
    log = CrypticSynchronizer.call(user: Current.user, url: Setting.current.source_url)
    redirect_to admin_syncs_path, (log.failed? ? :alert : :notice) => log.summary
  end
end
