# frozen_string_literal: true

require "test_helper"
require "rake"

class AdminTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("admin:create")
    Rake::Task["admin:create"].reenable
  end

  test "crea un administrador con EMAIL y PASSWORD" do
    with_env("EMAIL" => "jefa@rubipticos.test", "PASSWORD" => "secreto123") do
      assert_output(/Admin creado: jefa@rubipticos.test/) { Rake::Task["admin:create"].invoke }
    end

    assert User.find_by(email_address: "jefa@rubipticos.test").admin?
  end

  test "sin EMAIL o PASSWORD termina con un mensaje de uso" do
    with_env("EMAIL" => nil, "PASSWORD" => nil) do
      _out, err = capture_io do
        assert_raises(SystemExit) { Rake::Task["admin:create"].invoke }
      end
      assert_match(/Uso:/, err)
    end
  end

  private

  def with_env(values)
    previous = values.keys.index_with { |key| ENV[key] }
    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    previous.each { |key, value| ENV[key] = value }
  end
end
