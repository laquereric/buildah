# frozen_string_literal: true

require "open3"
require "json"

module Buildah
  # Main client class for interacting with buildah
  class Client
    attr_reader :options

    # Initialize a new Buildah client
    #
    # @param options [Hash] Configuration options
    # @option options [String] :buildah_path Path to buildah executable
    # @option options [Hash] :env Environment variables to set
    # @option options [Boolean] :debug Enable debug output
    def initialize(options = {})
      @options = {
        buildah_path: "buildah",
        env: {},
        debug: false
      }.merge(options)

      validate_buildah_availability!
    end

    # Check if buildah is available on the system
    #
    # @return [Boolean] True if buildah is available
    def self.buildah_available?
      _, _, status = Open3.capture3("which buildah")
      status.success?
    rescue StandardError
      false
    end

    # Get buildah version information
    #
    # @return [String] Buildah version string
    def self.buildah_version
      stdout, stderr, status = Open3.capture3("buildah version --format json")
      if status.success?
        version_info = JSON.parse(stdout)
        version_info.dig("version") || "unknown"
      else
        raise CommandError.new("Failed to get buildah version", stderr: stderr)
      end
    rescue JSON::ParserError
      # Fallback for older buildah versions without JSON support
      stdout, stderr, status = Open3.capture3("buildah version")
      if status.success?
        stdout.strip
      else
        raise CommandError.new("Failed to get buildah version", stderr: stderr)
      end
    end

    # Execute a buildah command
    #
    # @param command [Array<String>] Command arguments
    # @param input [String, nil] Input to send to command
    # @return [Hash] Command result with stdout, stderr, and status
    def execute(command, input: nil)
      full_command = [@options[:buildah_path]] + command
      env = ENV.to_h.merge(@options[:env])

      puts "Executing: #{full_command.join(' ')}" if @options[:debug]

      stdout, stderr, status = Open3.capture3(env, *full_command, stdin_data: input)

      result = {
        stdout: stdout,
        stderr: stderr,
        success: status.success?,
        exit_code: status.exitstatus
      }

      unless status.success?
        raise CommandError.new(
          "Command failed: #{full_command.join(' ')}",
          command: full_command,
          exit_code: status.exitstatus,
          stderr: stderr
        )
      end

      result
    end

    # Create a new container
    #
    # @param image [String] Base image name
    # @param options [Hash] Container creation options
    # @return [Buildah::Container] New container instance
    def from(image, options = {})
      Container.from(self, image, options)
    end

    # List containers
    #
    # @return [Array<Buildah::Container>] List of containers
    def containers
      Container.list(self)
    end

    # List images
    #
    # @return [Array<Buildah::Image>] List of images
    def images
      Image.list(self)
    end

    # Pull an image from registry
    #
    # @param image [String] Image name to pull
    # @param options [Hash] Pull options
    # @return [Buildah::Image] Pulled image
    def pull(image, options = {})
      Image.pull(self, image, options)
    end

    # Build an image from Containerfile/Dockerfile
    #
    # @param context [String] Build context path
    # @param options [Hash] Build options
    # @return [Buildah::Image] Built image
    def build(context, options = {})
      Builder.build(self, context, options)
    end

    # Get system information
    #
    # @return [Hash] System information
    def info
      result = execute(["info", "--format", "json"])
      JSON.parse(result[:stdout])
    rescue JSON::ParserError => e
      raise CommandError.new("Failed to parse info output: #{e.message}")
    end

    private

    def validate_buildah_availability!
      return if self.class.buildah_available?

      raise BuildahNotFoundError, "buildah command not found. Please install buildah."
    end
  end
end

