# frozen_string_literal: true

require_relative "lib/buildah/version"

Gem::Specification.new do |spec|
  spec.name = "buildah"
  spec.version = Buildah::VERSION
  spec.authors = ["Buildah Ruby Team"]
  spec.email = ["buildah-ruby@example.com"]

  spec.summary = "Ruby wrapper for the buildah container building tool"
  spec.description = "A comprehensive Ruby wrapper for buildah, providing an object-oriented interface to build OCI container images without requiring Docker or root privileges."
  spec.homepage = "https://github.com/buildah-ruby/buildah-ruby"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/buildah-ruby/buildah-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/buildah-ruby/buildah-ruby/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "json", "~> 2.0"

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "cucumber", "~> 9.0"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "yard", "~> 0.9"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
