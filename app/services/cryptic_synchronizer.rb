# frozen_string_literal: true

require "net/http"

# Trae el catálogo de crípticos por HTTP y lo guarda en la base.
#
#   CrypticSynchronizer.call(user: Current.user, url: Setting.current.source_url) # => SyncLog
#
# Reglas:
# - GET con timeout de 10 s. Si falla la red o el JSON no sirve, no se toca nada.
# - Si la versión y la URL son las mismas que en la última sincronización exitosa:
#   "Sin cambios". Si cambia cualquiera de las dos, se vuelve a sincronizar.
# - Cada críptico se identifica por su id de la fuente: se crea o se actualiza.
#   Su origen es el host de la URL de la última sincronización que lo trajo.
# - Un críptico inválido (o con id repetido) se saltea y se informa con su motivo.
# - Los que ya no vienen en la fuente se desactivan, nunca se borran.
#   Los que vienen en la fuente quedan activos (si habían desaparecido, se reactivan).
# - Cada corrida queda registrada en un SyncLog.
class CrypticSynchronizer
  class FetchError < StandardError; end

  TIMEOUT = 10

  # Campo del JSON => columna de la tabla cryptics.
  FIELD_MAP = {
    "enunciado" => :statement, "enumeracion" => :enumeration, "respuesta" => :answer,
    "definiciones" => :definitions, "indicadores" => :indicators, "material" => :material,
    "tipo" => :cryptic_type, "dificultad" => :difficulty, "ayuda" => :help,
    "explicacion" => :explanation, "autor" => :author
  }.freeze

  NETWORK_ERRORS = [
    Timeout::Error, SocketError, SystemCallError, IOError, OpenSSL::SSL::SSLError, Net::HTTPBadResponse
  ].freeze

  def self.call(...) = new(...).call

  def initialize(user:, url:)
    @user = user
    @url = url
    @counts = Hash.new(0)
    @rejections = []
    @seen_ids = []
  end

  def call
    catalog = fetch_catalog
    version = catalog.fetch("version")
    return log!(status: "unchanged", version:) if already_synced?(version)

    ActiveRecord::Base.transaction do
      catalog.fetch("cripticos").each { |item| import(item) }
      @counts[:deactivated] = Cryptic.active.where.not(source_id: @seen_ids).update_all(active: false)
      Setting.current.update!(last_synced_version: version, last_synced_url: @url)
    end
    log!(status: "ok", version:)
  rescue FetchError => e
    Rails.logger.error("[CrypticSynchronizer] #{@url}: #{e.message}")
    log!(status: "failed", error_message: e.message)
  end

  private

  def already_synced?(version)
    setting = Setting.current
    version == setting.last_synced_version && @url == setting.last_synced_url
  end

  def fetch_catalog
    response = http_get(parsed_url)
    raise FetchError, "La fuente respondió con el código HTTP #{response.code}." unless response.is_a?(Net::HTTPSuccess)

    catalog = JSON.parse(response.body)
    raise FetchError, "El catálogo no tiene el formato esperado." unless catalog.is_a?(Hash)
    raise FetchError, "El catálogo no indica su versión." if catalog["version"].blank?
    raise FetchError, "El catálogo no tiene la lista de crípticos." unless catalog["cripticos"].is_a?(Array)

    catalog
  rescue JSON::ParserError
    raise FetchError, "La respuesta de la fuente no es un JSON válido."
  rescue *NETWORK_ERRORS => e
    raise FetchError, "No se pudo conectar con la fuente (#{e.message})."
  end

  def parsed_url
    uri = URI.parse(@url.to_s)
    raise FetchError, "La URL de la fuente no es válida: #{@url}" unless uri.is_a?(URI::HTTP) && uri.host.present?

    uri
  rescue URI::InvalidURIError
    raise FetchError, "La URL de la fuente no es válida: #{@url}"
  end

  def http_get(uri)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                        open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
      http.get(uri.request_uri)
    end
  end

  # Crea o actualiza un críptico y lo deja activo, porque vino en la fuente.
  # Si viene inválido, se saltea y se anota el motivo: si ya existía, se queda
  # con su versión anterior.
  def import(item)
    source_id = item["id"] if item.is_a?(Hash)
    return reject!(nil, "no tiene id") if source_id.blank?
    return reject!(source_id, "el id está repetido en la fuente") if @seen_ids.include?(source_id)

    @seen_ids << source_id
    cryptic = Cryptic.find_or_initialize_by(source_id:)
    cryptic.assign_attributes(FIELD_MAP.to_h { |field, column| [ column, item[field] ] }.merge(active: true, origin:))
    persist(cryptic)
  end

  def persist(cryptic)
    new_record = cryptic.new_record?
    changed = cryptic.changed?
    return reject!(cryptic.source_id, cryptic.errors.full_messages.to_sentence) unless cryptic.save

    @counts[:created] += 1 if new_record
    @counts[:updated] += 1 if !new_record && changed
  end

  def reject!(id, reason)
    @rejections << { "id" => id, "motivo" => reason }
  end

  # De dónde vino el críptico: la API de la cátedra, un fork o un servidor local.
  def origin = parsed_url.port.in?([ 80, 443 ]) ? parsed_url.host : "#{parsed_url.host}:#{parsed_url.port}"

  def log!(**attrs)
    SyncLog.create!(user: @user, created_count: @counts[:created], updated_count: @counts[:updated],
                    deactivated_count: @counts[:deactivated], rejected_count: @rejections.size,
                    rejections: @rejections, **attrs)
  end
end
