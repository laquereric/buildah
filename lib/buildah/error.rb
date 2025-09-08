# frozen_string_literal: true

module Buildah
  # Base error class for all Buildah-related errors
  class Error < StandardError; end

  # Raised when buildah command is not found or not executable
  class BuildahNotFoundError < Error; end

  # Raised when buildah command execution fails
  class CommandError < Error
    attr_reader :command, :exit_code, :stderr

    def initialize(message, command: nil, exit_code: nil, stderr: nil)
      super(message)
      @command = command
      @exit_code = exit_code
      @stderr = stderr
    end
  end

  # Raised when container operations fail
  class ContainerError < Error; end

  # Raised when image operations fail
  class ImageError < Error; end

  # Raised when build operations fail
  class BuildError < Error; end

  # Raised when configuration operations fail
  class ConfigError < Error; end

  # Raised when invalid arguments are provided
  class ArgumentError < Error; end
end

