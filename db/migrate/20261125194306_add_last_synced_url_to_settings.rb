# frozen_string_literal: true

# La sincronización se saltea solo si coinciden la versión Y la URL de la última
# exitosa: si el admin cambia la fuente (un fork, un servidor local), se vuelve a traer.
class AddLastSyncedUrlToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :last_synced_url, :string
  end
end
