# frozen_string_literal: true

module Buildah
  # Represents a container image
  class Image
    attr_reader :client, :name, :id, :repository, :tag

    # Initialize an image instance
    #
    # @param client [Buildah::Client] Client instance
    # @param name [String] Image name
    # @param id [String] Image ID
    # @param repository [String] Image repository
    # @param tag [String] Image tag
    def initialize(client, name, id: nil, repository: nil, tag: nil)
      @client = client
      @name = name
      @id = id
      @repository = repository
      @tag = tag
    end

    # List all images
    #
    # @param client [Buildah::Client] Client instance
    # @return [Array<Buildah::Image>] List of images
    def self.list(client)
      result = client.execute(["images", "--format", "json"])
      images_data = JSON.parse(result[:stdout])

      images_data.map do |image_data|
        new(
          client,
          image_data["name"] || image_data["repository"],
          id: image_data["id"],
          repository: image_data["repository"],
          tag: image_data["tag"]
        )
      end
    rescue JSON::ParserError => e
      raise ImageError.new("Failed to parse images list: #{e.message}")
    rescue CommandError => e
      raise ImageError.new("Failed to list images: #{e.message}")
    end

    # Pull an image from registry
    #
    # @param client [Buildah::Client] Client instance
    # @param image [String] Image name to pull
    # @param options [Hash] Pull options
    # @option options [String] :authfile Authentication file path
    # @option options [String] :cert_dir Certificate directory
    # @option options [String] :creds Credentials (username:password)
    # @option options [Boolean] :quiet Suppress output
    # @return [Buildah::Image] Pulled image
    def self.pull(client, image, options = {})
      cmd = ["pull"]
      cmd += build_pull_options(options)
      cmd << image

      result = client.execute(cmd)
      new(client, image)
    rescue CommandError => e
      raise ImageError.new("Failed to pull image #{image}: #{e.message}")
    end

    # Push the image to registry
    #
    # @param destination [String] Destination registry/repository
    # @param options [Hash] Push options
    # @option options [String] :authfile Authentication file path
    # @option options [String] :cert_dir Certificate directory
    # @option options [String] :creds Credentials (username:password)
    # @option options [Boolean] :quiet Suppress output
    # @return [Hash] Command result
    def push(destination = nil, options = {})
      cmd = ["push"]
      cmd += self.class.build_push_options(options)
      cmd << (destination || @name)

      @client.execute(cmd)
    rescue CommandError => e
      raise ImageError.new("Failed to push image #{@name}: #{e.message}")
    end

    # Tag the image with a new name
    #
    # @param new_name [String] New image name/tag
    # @return [Hash] Command result
    def tag(new_name)
      @client.execute(["tag", @name, new_name])
    rescue CommandError => e
      raise ImageError.new("Failed to tag image #{@name}: #{e.message}")
    end

    # Remove the image
    #
    # @param options [Hash] Remove options
    # @option options [Boolean] :force Force removal
    # @return [Hash] Command result
    def rmi(options = {})
      cmd = ["rmi"]
      cmd << "--force" if options[:force]
      cmd << @name

      @client.execute(cmd)
    rescue CommandError => e
      raise ImageError.new("Failed to remove image #{@name}: #{e.message}")
    end

    # Inspect the image
    #
    # @return [Hash] Image inspection data
    def inspect
      result = @client.execute(["inspect", @name])
      JSON.parse(result[:stdout])
    rescue JSON::ParserError => e
      raise ImageError.new("Failed to parse inspect output: #{e.message}")
    rescue CommandError => e
      raise ImageError.new("Failed to inspect image #{@name}: #{e.message}")
    end

    # Get image history
    #
    # @return [Array<Hash>] Image history
    def history
      result = @client.execute(["history", "--format", "json", @name])
      JSON.parse(result[:stdout])
    rescue JSON::ParserError => e
      raise ImageError.new("Failed to parse history output: #{e.message}")
    rescue CommandError => e
      raise ImageError.new("Failed to get image history for #{@name}: #{e.message}")
    end

    private

    def self.build_pull_options(options)
      opts = []
      opts += ["--authfile", options[:authfile]] if options[:authfile]
      opts += ["--cert-dir", options[:cert_dir]] if options[:cert_dir]
      opts += ["--creds", options[:creds]] if options[:creds]
      opts << "--quiet" if options[:quiet]
      opts
    end

    def self.build_push_options(options)
      opts = []
      opts += ["--authfile", options[:authfile]] if options[:authfile]
      opts += ["--cert-dir", options[:cert_dir]] if options[:cert_dir]
      opts += ["--creds", options[:creds]] if options[:creds]
      opts << "--quiet" if options[:quiet]
      opts
    end
  end
end

