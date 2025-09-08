# frozen_string_literal: true

require_relative "buildah/version"
require_relative "buildah/error"
require_relative "buildah/client"
require_relative "buildah/container"
require_relative "buildah/image"
require_relative "buildah/builder"
require_relative "buildah/config"

module Buildah
  # Create a new Buildah client instance
  #
  # @param options [Hash] Configuration options
  # @return [Buildah::Client] A new client instance
  def self.new(options = {})
    Client.new(options)
  end

  # Check if buildah is available on the system
  #
  # @return [Boolean] True if buildah is available
  def self.available?
    Client.buildah_available?
  end

  # Get buildah version information
  #
  # @return [String] Buildah version string
  def self.version
    Client.buildah_version
  end
end
