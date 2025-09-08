# frozen_string_literal: true

module Buildah
  # Handles configuration operations for containers and images
  class Config
    attr_reader :client

    # Initialize a config instance
    #
    # @param client [Buildah::Client] Client instance
    def initialize(client)
      @client = client
    end

    # Configure a container or image
    #
    # @param target [String] Container ID or image name
    # @param options [Hash] Configuration options
    # @return [Hash] Command result
    def configure(target, options = {})
      cmd = ["config"]
      cmd += build_config_options(options)
      cmd << target

      @client.execute(cmd)
    rescue CommandError => e
      raise ConfigError.new("Failed to configure #{target}: #{e.message}")
    end

    # Set environment variables
    #
    # @param target [String] Container ID or image name
    # @param env_vars [Hash, Array<String>] Environment variables
    # @return [Hash] Command result
    def set_env(target, env_vars)
      options = { env: format_env_vars(env_vars) }
      configure(target, options)
    end

    # Set the working directory
    #
    # @param target [String] Container ID or image name
    # @param workdir [String] Working directory path
    # @return [Hash] Command result
    def set_workdir(target, workdir)
      configure(target, { workdir: workdir })
    end

    # Set the default command
    #
    # @param target [String] Container ID or image name
    # @param cmd [Array<String>, String] Command to set
    # @return [Hash] Command result
    def set_cmd(target, cmd)
      command = cmd.is_a?(Array) ? cmd.join(" ") : cmd
      configure(target, { cmd: command })
    end

    # Set the entrypoint
    #
    # @param target [String] Container ID or image name
    # @param entrypoint [Array<String>, String] Entrypoint to set
    # @return [Hash] Command result
    def set_entrypoint(target, entrypoint)
      entry = entrypoint.is_a?(Array) ? entrypoint.join(" ") : entrypoint
      configure(target, { entrypoint: entry })
    end

    # Expose ports
    #
    # @param target [String] Container ID or image name
    # @param ports [Array<String>, String] Ports to expose
    # @return [Hash] Command result
    def expose_ports(target, ports)
      port_list = Array(ports)
      configure(target, { port: port_list })
    end

    # Set user
    #
    # @param target [String] Container ID or image name
    # @param user [String] User specification (user:group)
    # @return [Hash] Command result
    def set_user(target, user)
      configure(target, { user: user })
    end

    # Add labels
    #
    # @param target [String] Container ID or image name
    # @param labels [Hash, Array<String>] Labels to add
    # @return [Hash] Command result
    def add_labels(target, labels)
      options = { label: format_labels(labels) }
      configure(target, options)
    end

    # Add annotations
    #
    # @param target [String] Container ID or image name
    # @param annotations [Hash, Array<String>] Annotations to add
    # @return [Hash] Command result
    def add_annotations(target, annotations)
      options = { annotation: format_annotations(annotations) }
      configure(target, options)
    end

    # Set volumes
    #
    # @param target [String] Container ID or image name
    # @param volumes [Array<String>] Volume specifications
    # @return [Hash] Command result
    def set_volumes(target, volumes)
      configure(target, { volume: Array(volumes) })
    end

    # Set the shell
    #
    # @param target [String] Container ID or image name
    # @param shell [Array<String>, String] Shell specification
    # @return [Hash] Command result
    def set_shell(target, shell)
      shell_cmd = shell.is_a?(Array) ? shell.join(" ") : shell
      configure(target, { shell: shell_cmd })
    end

    private

    def build_config_options(options)
      opts = []

      # Command and entrypoint
      opts += ["--cmd", options[:cmd]] if options[:cmd]
      opts += ["--entrypoint", options[:entrypoint]] if options[:entrypoint]
      opts += ["--shell", options[:shell]] if options[:shell]

      # Working directory and user
      opts += ["--workingdir", options[:workdir]] if options[:workdir]
      opts += ["--user", options[:user]] if options[:user]

      # Environment variables
      if options[:env]
        Array(options[:env]).each do |env|
          opts += ["--env", env]
        end
      end

      # Ports
      if options[:port]
        Array(options[:port]).each do |port|
          opts += ["--port", port]
        end
      end

      # Volumes
      if options[:volume]
        Array(options[:volume]).each do |volume|
          opts += ["--volume", volume]
        end
      end

      # Labels
      if options[:label]
        Array(options[:label]).each do |label|
          opts += ["--label", label]
        end
      end

      # Annotations
      if options[:annotation]
        Array(options[:annotation]).each do |annotation|
          opts += ["--annotation", annotation]
        end
      end

      # Architecture and OS
      opts += ["--arch", options[:arch]] if options[:arch]
      opts += ["--os", options[:os]] if options[:os]

      # Other options
      opts += ["--author", options[:author]] if options[:author]
      opts += ["--created-by", options[:created_by]] if options[:created_by]
      opts += ["--comment", options[:comment]] if options[:comment]

      opts
    end

    def format_env_vars(env_vars)
      case env_vars
      when Hash
        env_vars.map { |key, value| "#{key}=#{value}" }
      when Array
        env_vars
      else
        [env_vars.to_s]
      end
    end

    def format_labels(labels)
      case labels
      when Hash
        labels.map { |key, value| "#{key}=#{value}" }
      when Array
        labels
      else
        [labels.to_s]
      end
    end

    def format_annotations(annotations)
      case annotations
      when Hash
        annotations.map { |key, value| "#{key}=#{value}" }
      when Array
        annotations
      else
        [annotations.to_s]
      end
    end
  end
end

