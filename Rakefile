require "bundler/gem_helper"

Bundler::GemHelper.install_tasks(name: "manticore-client")
Bundler::GemHelper.install_tasks(name: "manticore-rails")

begin
  require "rspec/core/rake_task"

  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
rescue LoadError
  # no rspec available
end
