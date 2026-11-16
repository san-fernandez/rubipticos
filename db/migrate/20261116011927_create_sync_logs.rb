# frozen_string_literal: true

# Registro de cada sincronización del catálogo: quién la hizo, qué versión
# trajo y cuántos crípticos se crearon, actualizaron, desactivaron o rechazaron.
class CreateSyncLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :sync_logs do |t|
      # Opcional: si el seed corre sin admin, la sincronización queda sin usuario.
      t.references :user, foreign_key: true
      t.string :version
      t.string :status, null: false
      t.integer :created_count, null: false, default: 0
      t.integer :updated_count, null: false, default: 0
      t.integer :deactivated_count, null: false, default: 0
      t.integer :rejected_count, null: false, default: 0
      t.json :rejections, null: false, default: []
      t.text :error_message

      t.timestamps
    end

    add_check_constraint :sync_logs, "status IN ('ok', 'unchanged', 'failed')", name: "sync_logs_status_check"
  end
end
