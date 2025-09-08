# frozen_string_literal: true

RSpec.describe Buildah::Container do
  let(:client) { double("client") }
  let(:container) { described_class.new(client, "container123", name: "test-container", image: "alpine") }

  describe "#initialize" do
    it "sets container attributes" do
      expect(container.client).to eq(client)
      expect(container.id).to eq("container123")
      expect(container.name).to eq("test-container")
      expect(container.image).to eq("alpine")
    end
  end

  describe ".from" do
    it "creates container from image" do
      allow(client).to receive(:execute).and_return({ stdout: "container456\n" })
      
      result = described_class.from(client, "alpine")
      
      expect(client).to have_received(:execute).with(["from", "alpine"])
      expect(result.id).to eq("container456")
      expect(result.image).to eq("alpine")
    end

    it "creates container with name" do
      allow(client).to receive(:execute).and_return({ stdout: "container456\n" })
      
      result = described_class.from(client, "alpine", name: "my-container")
      
      expect(client).to have_received(:execute).with(["from", "--name", "my-container", "alpine"])
      expect(result.name).to eq("my-container")
    end

    it "raises ContainerError on failure" do
      allow(client).to receive(:execute).and_raise(Buildah::CommandError.new("Failed"))
      
      expect { described_class.from(client, "alpine") }.to raise_error(Buildah::ContainerError)
    end
  end

  describe ".list" do
    it "lists containers" do
      json_output = '[{"containerId": "abc123", "containerName": "test", "imageName": "alpine"}]'
      allow(client).to receive(:execute).and_return({ stdout: json_output })
      
      result = described_class.list(client)
      
      expect(client).to have_received(:execute).with(["containers", "--format", "json"])
      expect(result).to have(1).item
      expect(result.first.id).to eq("abc123")
      expect(result.first.name).to eq("test")
      expect(result.first.image).to eq("alpine")
    end

    it "raises ContainerError on invalid JSON" do
      allow(client).to receive(:execute).and_return({ stdout: "invalid json" })
      expect { described_class.list(client) }.to raise_error(Buildah::ContainerError)
    end
  end

  describe "#run" do
    it "runs command in container" do
      allow(client).to receive(:execute).and_return({ stdout: "output" })
      
      result = container.run(["echo", "hello"])
      
      expect(client).to have_received(:execute).with(["run", "container123", "echo", "hello"])
      expect(result[:stdout]).to eq("output")
    end

    it "runs string command" do
      allow(client).to receive(:execute).and_return({ stdout: "output" })
      
      container.run("echo hello")
      
      expect(client).to have_received(:execute).with(["run", "container123", "echo hello"])
    end

    it "includes run options" do
      allow(client).to receive(:execute).and_return({ stdout: "output" })
      
      container.run(["echo", "hello"], workdir: "/tmp", user: "root")
      
      expect(client).to have_received(:execute).with([
        "run", "--workingdir", "/tmp", "--user", "root", "container123", "echo", "hello"
      ])
    end
  end

  describe "#add" do
    it "adds files to container" do
      allow(client).to receive(:execute).and_return({ stdout: "success" })
      
      container.add("/host/file", "/container/file")
      
      expect(client).to have_received(:execute).with(["add", "container123", "/host/file", "/container/file"])
    end

    it "includes add options" do
      allow(client).to receive(:execute).and_return({ stdout: "success" })
      
      container.add("/host/file", "/container/file", chown: "user:group")
      
      expect(client).to have_received(:execute).with([
        "add", "--chown", "user:group", "container123", "/host/file", "/container/file"
      ])
    end
  end

  describe "#copy" do
    it "copies files to container" do
      allow(client).to receive(:execute).and_return({ stdout: "success" })
      
      container.copy("/host/file", "/container/file")
      
      expect(client).to have_received(:execute).with(["copy", "container123", "/host/file", "/container/file"])
    end
  end

  describe "#config" do
    it "configures container" do
      allow(client).to receive(:execute).and_return({ stdout: "success" })
      
      container.config(cmd: "echo hello", port: "8080")
      
      expect(client).to have_received(:execute).with([
        "config", "--cmd", "echo hello", "--port", "8080", "container123"
      ])
    end
  end

  describe "#commit" do
    it "commits container to image" do
      allow(client).to receive(:execute).and_return({ stdout: "sha256:abc123\n" })
      allow(Buildah::Image).to receive(:new).and_return(double("image"))
      
      result = container.commit("my-image")
      
      expect(client).to have_received(:execute).with(["commit", "container123", "my-image"])
      expect(Buildah::Image).to have_received(:new).with(client, "my-image", id: "sha256:abc123")
    end
  end

  describe "#mount" do
    it "mounts container filesystem" do
      allow(client).to receive(:execute).and_return({ stdout: "/tmp/mount/path\n" })
      
      result = container.mount
      
      expect(client).to have_received(:execute).with(["mount", "container123"])
      expect(result).to eq("/tmp/mount/path")
    end
  end

  describe "#umount" do
    it "unmounts container filesystem" do
      allow(client).to receive(:execute).and_return({ stdout: "success" })
      
      container.umount
      
      expect(client).to have_received(:execute).with(["umount", "container123"])
    end
  end

  describe "#rm" do
    it "removes container" do
      allow(client).to receive(:execute).and_return({ stdout: "success" })
      
      container.rm
      
      expect(client).to have_received(:execute).with(["rm", "container123"])
    end
  end

  describe "#inspect" do
    it "inspects container" do
      json_output = '{"Id": "container123", "Config": {}}'
      allow(client).to receive(:execute).and_return({ stdout: json_output })
      
      result = container.inspect
      
      expect(client).to have_received(:execute).with(["inspect", "container123"])
      expect(result).to eq({ "Id" => "container123", "Config" => {} })
    end

    it "raises ContainerError on invalid JSON" do
      allow(client).to receive(:execute).and_return({ stdout: "invalid json" })
      expect { container.inspect }.to raise_error(Buildah::ContainerError)
    end
  end
end

