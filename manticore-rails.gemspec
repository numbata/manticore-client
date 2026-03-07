# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "manticore-rails"
  spec.version = File.read(File.expand_path("lib/manticore-rails/version.rb", __dir__))
                     .match(/VERSION\s*=\s*"([^"]+)"/)[1]
  spec.platform = Gem::Platform::RUBY
  spec.authors = ["Aleksandr Subbota"]
  spec.email = ["subbota@gmail.com"]
  spec.homepage = "https://github.com/numbata/manticore-client"
  spec.summary = "Rails integration for ManticoreSearch"
  spec.description = "ActiveRecord DSL for ManticoreSearch: index definitions, " \
                     "full-text search, auto-indexing callbacks, and rake tasks."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"
  spec.metadata = {
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "documentation_uri" => "#{spec.homepage}/blob/main/README-rails.md",
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "rubygems_mfa_required" => "true"
  }

  spec.add_dependency "activerecord", ">= 6.0"
  spec.add_dependency "activesupport", ">= 6.0"
  spec.add_dependency "manticore-client", "~> 1.0"
  spec.add_dependency "zeitwerk"

  spec.files = %w[LICENSE.txt README-rails.md] + Dir.glob("lib/manticore-rails.rb") +
               Dir.glob("lib/manticore-rails/**/*.rb") +
               Dir.glob("lib/tasks/**/*.rake")

  spec.executables = []
  spec.require_paths = ["lib"]
end
