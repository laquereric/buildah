# frozen_string_literal: true

module Buildah
  # Handles building images from Containerfiles/Dockerfiles
  class Builder
    attr_reader :client

    # Initialize a builder instance
    #
    # @param client [Buildah::Client] Client instance
    def initialize(client)
      @client = client
    end

    # Build an image from Containerfile/Dockerfile
    #
    # @param client [Buildah::Client] Client instance
    # @param context [String] Build context path
    # @param options [Hash] Build options
    # @option options [String] :file Containerfile/Dockerfile path
    # @option options [String] :tag Image tag
    # @option options [Array<String>] :build_arg Build arguments
    # @option options [String] :target Target stage for multi-stage builds
    # @option options [Boolean] :no_cache Don't use cache
    # @option options [Boolean] :pull Always pull base images
    # @option options [Boolean] :quiet Suppress output
    # @option options [String] :format Output format (oci or docker)
    # @return [Buildah::Image] Built image
    def self.build(client, context, options = {})
      cmd = ["build"]
      cmd += build_options(options)
      cmd << context

      result = client.execute(cmd)
      
      # Extract image ID from output if available
      image_id = extract_image_id(result[:stdout])
      image_name = options[:tag] || image_id

      Image.new(client, image_name, id: image_id)
    rescue CommandError => e
      raise BuildError.new("Failed to build image: #{e.message}")
    end

    # Build an image using build-using-dockerfile (bud) command
    #
    # @param client [Buildah::Client] Client instance
    # @param context [String] Build context path
    # @param options [Hash] Build options (same as build method)
    # @return [Buildah::Image] Built image
    def self.bud(client, context, options = {})
      cmd = ["bud"]
      cmd += build_options(options)
      cmd << context

      result = client.execute(cmd)
      
      # Extract image ID from output if available
      image_id = extract_image_id(result[:stdout])
      image_name = options[:tag] || image_id

      Image.new(client, image_name, id: image_id)
    rescue CommandError => e
      raise BuildError.new("Failed to build image with bud: #{e.message}")
    end

    private

    def self.build_options(options)
      opts = []
      
      # File options
      opts += ["--file", options[:file]] if options[:file]
      opts += ["-f", options[:dockerfile]] if options[:dockerfile]
      
      # Tag options
      opts += ["--tag", options[:tag]] if options[:tag]
      opts += ["-t", options[:tag]] if options[:t] && !options[:tag]
      
      # Build arguments
      if options[:build_arg]
        Array(options[:build_arg]).each do |arg|
          opts += ["--build-arg", arg]
        end
      end
      
      # Target stage
      opts += ["--target", options[:target]] if options[:target]
      
      # Cache options
      opts << "--no-cache" if options[:no_cache]
      opts << "--pull" if options[:pull]
      opts << "--pull-always" if options[:pull_always]
      
      # Output options
      opts << "--quiet" if options[:quiet]
      opts += ["--format", options[:format]] if options[:format]
      
      # Layer options
      opts << "--squash" if options[:squash]
      opts << "--layers" if options[:layers]
      
      # Platform options
      opts += ["--platform", options[:platform]] if options[:platform]
      opts += ["--arch", options[:arch]] if options[:arch]
      opts += ["--os", options[:os]] if options[:os]
      
      # Security options
      opts += ["--isolation", options[:isolation]] if options[:isolation]
      opts << "--disable-compression" if options[:disable_compression]
      
      # Network options
      opts += ["--network", options[:network]] if options[:network]
      
      # Volume options
      if options[:volume]
        Array(options[:volume]).each do |volume|
          opts += ["--volume", volume]
        end
      end
      
      # Environment options
      if options[:env]
        Array(options[:env]).each do |env|
          opts += ["--env", env]
        end
      end
      
      # Label options
      if options[:label]
        Array(options[:label]).each do |label|
          opts += ["--label", label]
        end
      end
      
      # Annotation options
      if options[:annotation]
        Array(options[:annotation]).each do |annotation|
          opts += ["--annotation", annotation]
        end
      end
      
      opts
    end

    def self.extract_image_id(output)
      # Try to extract image ID from buildah output
      # This is a best-effort approach as output format may vary
      lines = output.split("\n")
      
      # Look for lines containing image IDs (typically SHA256 hashes)
      lines.each do |line|
        if line.match(/^[a-f0-9]{64}$/) || line.match(/sha256:[a-f0-9]{64}/)
          return line.strip
        end
        
        # Sometimes the ID is in a line like "Successfully built abc123"
        if line.match(/Successfully built ([a-f0-9]+)/)
          return $1
        end
        
        # Or in a line like "--> abc123"
        if line.match(/^--> ([a-f0-9]+)/)
          return $1
        end
      end
      
      # If we can't extract an ID, return nil
      nil
    end
  end
end

