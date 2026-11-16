# frozen_string_literal: true

# Valida que el juego de palabras de un críptico sea correcto, según su tipo.
# Solo algunos tipos se pueden verificar automáticamente; los demás pasan.
class CrypticWordplayValidator < ActiveModel::Validator
  RULES = {
    "doble_definicion" => :check_double_definition,
    "oculta" => :check_hidden,
    "anagrama" => :check_anagram,
    "iniciales" => :check_initials,
    "finales" => :check_finals
  }.freeze

  # Palabras de unión que no aportan letras en iniciales y finales.
  # Ejemplo: en «álbum, casa y amor» las finales son M-A-R, sin la «y».
  CONNECTORS = %w[Y E O U NI].freeze

  def validate(record)
    rule = RULES[record.cryptic_type]
    send(rule, record) if rule
  end

  private

  def check_double_definition(record)
    return if Array(record.definitions).size == 2

    record.errors.add(:definitions, "tienen que ser exactamente 2 en una doble definición")
  end

  # La respuesta está escrita de corrido dentro del material.
  def check_hidden(record)
    return if material_text(record).include?(answer(record))

    record.errors.add(:material, "no esconde la respuesta")
  end

  # El material tiene exactamente las mismas letras que la respuesta.
  def check_anagram(record)
    return if material_text(record).chars.sort == answer(record).chars.sort

    record.errors.add(:material, "no tiene las mismas letras que la respuesta")
  end

  def check_initials(record)
    return if material_words(record).map { |word| word[0] }.join == answer(record)

    record.errors.add(:material, "no forma la respuesta con sus primeras letras")
  end

  def check_finals(record)
    return if material_words(record).map { |word| word[-1] }.join == answer(record)

    record.errors.add(:material, "no forma la respuesta con sus últimas letras")
  end

  def answer(record) = TextNormalizer.call(record.answer)

  def material_text(record) = TextNormalizer.call(Array(record.material).join)

  def material_words(record)
    Array(record.material).join(" ").split
                          .map { |word| TextNormalizer.call(word) }
                          .reject { |word| word.empty? || CONNECTORS.include?(word) }
  end
end
