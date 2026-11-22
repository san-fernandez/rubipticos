# frozen_string_literal: true

# Normaliza un texto para comparar respuestas: sin tildes, sin mayúsculas,
# sin espacios ni signos. La Ñ se conserva y se distingue de la N.
#
#   TextNormalizer.call("  Jamón ") # => "JAMON"
#   TextNormalizer.call("año")      # => "AÑO"
#
# No se usa unicode_normalize(:nfd) a secas porque también le sacaría la
# tilde a la ñ (la convertiría en N).
class TextNormalizer
  ACCENTS = { "Á" => "A", "É" => "E", "Í" => "I", "Ó" => "O", "Ú" => "U", "Ü" => "U" }.freeze

  def self.call(text)
    text.to_s.upcase.gsub(/[ÁÉÍÓÚÜ]/, ACCENTS).gsub(/[^A-ZÑ]/, "")
  end
end
