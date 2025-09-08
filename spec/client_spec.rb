# frozen_string_literal: true

RSpec.describe Buildah::Client do
  let(:client) { described_class.new }

  before do
    allow(described_class).to receive(:buildah_available?).and_return(true)
  end

  describe "#initialize" do
    it "sets default options" do
      expect(client.options[:buildah_path]).to eq("buildah")
      expect(client.options[:env]).to eq({})
      expect(client.options[:debug]).to be false
    end

    it "merges custom options" do
      custom_client = described_class.new(debug: true, buildah_path: "/usr/bin/buildah")
      expect(custom_client.options[:debug]).to be true
      expect(custom_client.options[:buildah_path]).to eq("/usr/bin/buildah")
    end

    it "raises error when buildah is not available" do
      allow(described_class).to receive(:buildah_available?).and_return(false)
      expect { described_class.new }.to raise_error(Buildah::BuildahNotFoundError)
    end
  end

  describe ".buildah_available?" do
    it "returns true when buildah is available" do
      allow(Open3).to receive(:capture3).with("which buildah").and_return([nil, nil, double(success?: true)])
      expect(described_class.buildah_available?).to be true
    end

    it "returns false when buildah is not available" do
      allow(Open3).to receive(:capture3).with("which buildah").and_return([nil, nil, double(success?: false)])
      expect(described_class.buildah_available?).to be false
    end

    it "returns false when command raises error" do
      allow(Open3).to receive(:capture3).and_raise(StandardError)
      expect(described_class.buildah_available?).to be false
    end
  end

  describe ".buildah_version" do
    context "with JSON format support" do
      it "returns version from JSON output" do
        json_output = '{"version": "1.23.0"}'
        allow(Open3).to receive(:capture3).with("buildah version --format json")
                                          .and_return([json_output, "", double(success?: true)])
        expect(described_class.buildah_version).to eq("1.23.0")
      end
    end

    context "without JSON format support" do
      it "falls back to plain version command" do
        allow(Open3).to receive(:capture3).with("buildah version --format json")
                                          .and_return(["", "error", double(success?: false)])
        allow(Open3).to receive(:capture3).with("buildah version")
                                          .and_return(["buildah version 1.23.0", "", double(success?: true)])
        expect(described_class.buildah_version).to eq("buildah version 1.23.0")
      end
    end

    it "raises error when version command fails" do
      allow(Open3).to receive(:capture3).with("buildah version --format json")
                                        .and_return(["", "error", double(success?: false)])
      allow(Open3).to receive(:capture3).with("buildah version")
                                        .and_return(["", "error", double(success?: false)])
      expect { described_class.buildah_version }.to raise_error(Buildah::CommandError)
    end
  end

  describe "#execute" do
    it "executes buildah command successfully" do
      allow(Open3).to receive(:capture3).and_return(["output", "", double(success?: true, exitstatus: 0)])
      result = client.execute(["version"])
      
      expect(result[:stdout]).to eq("output")
      expect(result[:stderr]).to eq("")
      expect(result[:success]).to be true
      expect(result[:exit_code]).to eq(0)
    end

    it "raises CommandError on failure" do
      allow(Open3).to receive(:capture3).and_return(["", "error", double(success?: false, exitstatus: 1)])
      
      expect { client.execute(["invalid"]) }.to raise_error(Buildah::CommandError) do |error|
        expect(error.exit_code).to eq(1)
        expect(error.stderr).to eq("error")
      end
    end

    it "includes environment variables" do
      client = described_class.new(env: { "TEST_VAR" => "test_value" })
      expected_env = ENV.to_h.merge("TEST_VAR" => "test_value")
      
      allow(Open3).to receive(:capture3).and_return(["", "", double(success?: true, exitstatus: 0)])
      client.execute(["version"])
      
      expect(Open3).to have_received(:capture3).with(expected_env, "buildah", "version", stdin_data: nil)
    end
  end

  describe "#from" do
    it "creates a container from image" do
      allow(Buildah::Container).to receive(:from).and_return(double("container"))
      result = client.from("alpine")
      expect(Buildah::Container).to have_received(:from).with(client, "alpine", {})
    end
  end

  describe "#containers" do
    it "lists containers" do
      allow(Buildah::Container).to receive(:list).and_return([])
      result = client.containers
      expect(Buildah::Container).to have_received(:list).with(client)
    end
  end

  describe "#images" do
    it "lists images" do
      allow(Buildah::Image).to receive(:list).and_return([])
      result = client.images
      expect(Buildah::Image).to have_received(:list).with(client)
    end
  end

  describe "#pull" do
    it "pulls an image" do
      allow(Buildah::Image).to receive(:pull).and_return(double("image"))
      result = client.pull("alpine")
      expect(Buildah::Image).to have_received(:pull).with(client, "alpine", {})
    end
  end

  describe "#build" do
    it "builds an image" do
      allow(Buildah::Builder).to receive(:build).and_return(double("image"))
      result = client.build(".")
      expect(Buildah::Builder).to have_received(:build).with(client, ".", {})
    end
  end

  describe "#info" do
    it "returns system information" do
      json_output = '{"host": {"os": "linux"}}'
      allow(client).to receive(:execute).and_return({ stdout: json_output })
      
      result = client.info
      expect(result).to eq({ "host" => { "os" => "linux" } })
    end

    it "raises error on invalid JSON" do
      allow(client).to receive(:execute).and_return({ stdout: "invalid json" })
      expect { client.info }.to raise_error(Buildah::CommandError)
    end
  end
end

