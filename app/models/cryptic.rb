# frozen_string_literal: true

# Un críptico del catálogo. Viene de la API de la cátedra (CrypticSynchronizer)
# y el juego siempre lo lee desde la base.
class Cryptic < ApplicationRecord
  TYPES = %w[anagrama oculta charada contenedor inversion supresion homofono
             doble_definicion iniciales finales sustitucion simbolos combinada].freeze
  DIFFICULTIES = %w[facil medio avanzado].freeze

  # Nombres para mostrar en la interfaz.
  TYPE_LABELS = {
    "anagrama" => "Anagrama", "oculta" => "Oculta", "charada" => "Charada",
    "contenedor" => "Contenedor", "inversion" => "Inversión", "supresion" => "Supresión",
    "homofono" => "Homófono", "doble_definicion" => "Doble definición",
    "iniciales" => "Iniciales", "finales" => "Finales", "sustitucion" => "Sustitución",
    "simbolos" => "Símbolos", "combinada" => "Combinada"
  }.freeze
  DIFFICULTY_LABELS = { "facil" => "Fácil", "medio" => "Medio", "avanzado" => "Avanzado" }.freeze
  STATUSES = %w[activos inactivos].freeze
  DAILY_FILTERS = { "reservados" => "Reservados para el del día", "comunes" => "Comunes" }.freeze

  validates :source_id, presence: true, uniqueness: true
  validates :statement, :answer, :enumeration, presence: true
  validates :cryptic_type, inclusion: { in: TYPES }
  validates :difficulty, inclusion: { in: DIFFICULTIES }
  validate :enumeration_matches_answer
  validate :fragments_appear_in_statement
  validates_with CrypticWordplayValidator

  # Filtros del admin. Con el valor vacío devuelven todos (un scope que da nil
  # equivale a all), así se pueden encadenar sin if en el controlador.
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  # Críptico del día: el admin reserva crípticos con daily_candidate (marca local,
  # la API no la manda y el sincronizador no la pisa). DailyCryptic elige entre
  # los reservados y CrypticPicker sortea entre los comunes, así ninguno se juega antes de tiempo.
  scope :daily_candidates, -> { where(daily_candidate: true) }
  scope :regular, -> { where(daily_candidate: false) }
  scope :by_difficulty, ->(difficulty) { where(difficulty:) if difficulty.present? }
  scope :by_type, ->(cryptic_type) { where(cryptic_type:) if cryptic_type.present? }
  scope :by_origin, ->(origin) { where(origin:) if origin.present? }
  scope :by_status, lambda { |status|
    case status
    when "activos" then active
    when "inactivos" then inactive
    end
  }
  scope :by_daily, lambda { |daily|
    case daily
    when "reservados" then daily_candidates
    when "comunes" then regular
    end
  }

  def self.origins = distinct.where.not(origin: nil).order(:origin).pluck(:origin)

  def normalized_answer = TextNormalizer.call(answer)

  def type_label = TYPE_LABELS.fetch(cryptic_type, cryptic_type)

  def difficulty_label = DIFFICULTY_LABELS.fetch(difficulty, difficulty)

  private

  # "(6)" => 6 letras; "(4,3)" => 7. Las tildes y los espacios no cuentan.
  def enumeration_matches_answer
    return if enumeration.blank? || answer.blank?

    expected = enumeration.scan(/\d+/).sum(&:to_i)
    return if expected == normalized_answer.length

    errors.add(:enumeration, "no coincide con el largo de la respuesta (#{normalized_answer.length} letras)")
  end

  # Cada definición, indicador y material tiene que estar escrito tal cual en el enunciado.
  def fragments_appear_in_statement
    (Array(definitions) + Array(indicators) + Array(material)).each do |fragment|
      next if statement.to_s.include?(fragment.to_s)

      errors.add(:statement, "no contiene «#{fragment}»")
    end
  end
end
