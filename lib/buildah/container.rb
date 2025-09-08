# frozen_string_literal: true

module Buildah
  # Represents a buildah working container
  class Container
    attr_reader :client, :id, :name, :image

    # Initialize a container instance
    #
    # @param client [Buildah::Client] Client instance
    # @param id [String] Container ID
    # @param name [String] Container name
    # @param image [String] Base image name
    def initialize(client, id, name: nil, image: nil)
      @client = client
      @id = id
      @name = name
      @image = image
    end

    # Create a new container from an image
    #
    # @param client [Buildah::Client] Client instance
    # @param image [String] Base image name
    # @param options [Hash] Container creation options
    # @option options [String] :name Container name
    # @option options [Array<String>] :pull Pull policy
    # @return [Buildah::Container] New container instance
    def self.from(client, image, options = {})
      command = ["from"]
      command += ["--name", options[:name]] if options[:name]
      command += ["--pull", options[:pull]] if options[:pull]
      command << image

      result = client.execute(command)
      container_id = result[:stdout].strip

      new(client, container_id, name: options[:name], image: image)
    rescue CommandError => e
      raise ContainerError.new("Failed to create container from #{image}: #{e.message}")
    end

    # List all containers
    #
    # @param client [Buildah::Client] Client instance
    # @return [Array<Buildah::Container>] List of containers
    def self.list(client)
      result = client.execute(["containers", "--format", "json"])
      containers_data = JSON.parse(result[:stdout])

      containers_data.map do |container_data|
        new(
          client,
          container_data["containerId"],
          name: container_data["containerName"],
          image: container_data["imageName"]
        )
      end
    rescue JSON::ParserError => e
      raise ContainerError.new("Failed to parse containers list: #{e.message}")
    rescue CommandError => e
      raise ContainerError.new("Failed to list containers: #{e.message}")
    end

    # Run a command inside the container
    #
    # @param command [Array<String>, String] Command to run
    # @param options [Hash] Run options
    # @return [Hash] Command result
    def run(command, options = {})
      cmd = ["run"]
      cmd += build_run_options(options)
      cmd << @id
      cmd += command.is_a?(Array) ? command : [command]

      @client.execute(cmd)
    rescue CommandError => e
      raise ContainerError.new("Failed to run command in container #{@id}: #{e.message}")
    end

    # Add files to the container
    #
    # @param source [String] Source path
    # @param destination [String] Destination path in container
    # @param options [Hash] Add options
    # @return [Hash] Command result
    def add(source, destination, options = {})
      cmd = ["add"]
      cmd += build_add_options(options)
      cmd += [@id, source, destination]

      @client.execute(cmd)
    rescue CommandError => e
      raise ContainerError.new("Failed to add files to container #{@id}: #{e.message}")
    end

    # Copy files to the container
    #
    # @param source [String] Source path
    # @param destination [String] Destination path in container
    # @param options [Hash] Copy options
    # @return [Hash] Command result
    def copy(source, destination, options = {})
      cmd = ["copy"]
      cmd += build_copy_options(options)
      cmd += [@id, source, destination]

      @client.execute(cmd)
    rescue CommandError => e
      raise ContainerError.new("Failed to copy files to container #{@id}: #{e.message}")
    end

    # Configure the container
    #
    # @param options [Hash] Configuration options
    # @return [Hash] Command result
    def config(options = {})
      cmd = ["config"]
      cmd += build_config_options(options)
      cmd << @id

      @client.execute(cmd)
    rescue CommandError => e
      raise ContainerError.new("Failed to configure container #{@id}: #{e.message}")
    end

    # Commit the container to an image
    #
    # @param image_name [String] Name for the new image
    # @param options [Hash] Commit options
    # @return [Buildah::Image] New image instance
    def commit(image_name, options = {})
      cmd = ["commit"]
      cmd += build_commit_options(options)
      cmd += [@id, image_name]

      result = @client.execute(cmd)
      Image.new(@client, image_name, id: result[:stdout].strip)
    rescue CommandError => e
      raise ContainerError.new("Failed to commit container #{@id}: #{e.message}")
    end

    # Mount the container's filesystem
    #
    # @return [String] Mount point path
    def mount
      result = @client.execute(["mount", @id])
      result[:stdout].strip
    rescue CommandError => e
      raise ContainerError.new("Failed to mount container #{@id}: #{e.message}")
    end

    # Unmount the container's filesystem
    #
    # @return [Hash] Command result
    def umount
      @client.execute(["umount", @id])
    rescue CommandError => e
      raise ContainerError.new("Failed to unmount container #{@id}: #{e.message}")
    end

    # Remove the container
    #
    # @return [Hash] Command result
    def rm
      @client.execute(["rm", @id])
    rescue CommandError => e
      raise ContainerError.new("Failed to remove container #{@id}: #{e.message}")
    end

    # Inspect the container
    #
    # @return [Hash] Container inspection data
    def inspect
      result = @client.execute(["inspect", @id])
      JSON.parse(result[:stdout])
    rescue JSON::ParserError => e
      raise ContainerError.new("Failed to parse inspect output: #{e.message}")
    rescue CommandError => e
      raise ContainerError.new("Failed to inspect container #{@id}: #{e.message}")
    end

    private

    def build_run_options(options)
      opts = []
      opts += ["--workingdir", options[:workdir]] if options[:workdir]
      opts += ["--user", options[:user]] if options[:user]
      opts += ["--env", options[:env]] if options[:env]
      opts
    end

    def build_add_options(options)
      opts = []
      opts += ["--chown", options[:chown]] if options[:chown]
      opts
    end

    def build_copy_options(options)
      opts = []
      opts += ["--chown", options[:chown]] if options[:chown]
      opts
    end

    def build_config_options(options)
      opts = []
      opts += ["--cmd", options[:cmd]] if options[:cmd]
      opts += ["--entrypoint", options[:entrypoint]] if options[:entrypoint]
      opts += ["--env", options[:env]] if options[:env]
      opts += ["--port", options[:port]] if options[:port]
      opts += ["--workingdir", options[:workdir]] if options[:workdir]
      opts += ["--user", options[:user]] if options[:user]
      opts
    end

    def build_commit_options(options)
      opts = []
      opts += ["--format", options[:format]] if options[:format]
      opts += ["--squash"] if options[:squash]
      opts
    end
  end
end

