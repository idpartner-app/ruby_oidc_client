# frozen_string_literal: true

require_relative "lib/ruby_oidc_client/version"

Gem::Specification.new do |spec|
  spec.name = "ruby_oidc_client"
  spec.version = RubyOidcClient::VERSION
  spec.authors = ["Giovanni Alberto"]
  spec.email = ["delirable@gmail.com"]

  spec.summary = "A Ruby client for interacting with OpenID Connect providers using the IDPartner class."
  spec.description = "The IDPartner gem provides a Ruby client for engaging with OpenID Connect providers, simplifying the process of authorization, token acquisition, and user information retrieval. It supports various authentication methods and handles endpoint discovery via well-known configuration. The gem encapsulates the complexities of generating, signing, and verifying JWTs, making OpenID Connect integration straightforward and secure."
  spec.homepage = "https://github.com/idpartner-app/ruby_oidc_client"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/idpartner-app/ruby_oidc_client"
  spec.metadata["changelog_uri"] = "https://github.com/idpartner-app/ruby_oidc_client/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "json-jwt", "~> 1.16.3"

  # Optionally, within your gemspec file if you prefer to declare dev/test dependencies here
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "vcr", "~> 6.2.0"
  spec.add_development_dependency "webmock", "~> 3.19.1"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
