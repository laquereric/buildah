# frozen_string_literal: true

Given("buildah is available on the system") do
  # Mock buildah availability for testing
  allow(Buildah::Client).to receive(:buildah_available?).and_return(true)
  allow(Buildah::Client).to receive(:buildah_version).and_return("1.23.0")
end

When("I create a new Buildah client") do
  allow(Open3).to receive(:capture3).and_return(["", "", double(success?: true)])
  @client = Buildah.new
end

Then("the client should be initialized successfully") do
  expect(@client).to be_a(Buildah::Client)
end

When("I check if buildah is available") do
  @availability = Buildah.available?
end

Then("it should return true") do
  expect(@availability).to be true
end

When("I get the buildah version") do
  @version = Buildah.version
end

Then("it should return a version string") do
  expect(@version).to be_a(String)
  expect(@version).not_to be_empty
end

Given("I have a Buildah client") do
  allow(Open3).to receive(:capture3).and_return(["", "", double(success?: true)])
  @client = Buildah.new
end

When("I create a container from {string} image") do |image|
  allow(@client).to receive(:execute).with(["from", image]).and_return({ stdout: "container123\n" })
  @container = @client.from(image)
  @image_name = image
end

Then("a new container should be created") do
  expect(@container).to be_a(Buildah::Container)
end

Then("the container should have the correct image reference") do
  expect(@container.image).to eq(@image_name)
end

Given("I have created a container from {string} image") do |image|
  allow(@client).to receive(:execute).with(["from", image]).and_return({ stdout: "container123\n" })
  @container = @client.from(image)
end

When("I list all containers") do
  json_output = '[{"containerId": "container123", "containerName": null, "imageName": "alpine"}]'
  allow(@client).to receive(:execute).with(["containers", "--format", "json"]).and_return({ stdout: json_output })
  @containers = @client.containers
end

Then("the container should be in the list") do
  expect(@containers).to have(1).item
  expect(@containers.first.id).to eq("container123")
end

Given("I have a container from {string} image") do |image|
  allow(@client).to receive(:execute).with(["from", image]).and_return({ stdout: "container123\n" })
  @container = @client.from(image)
end

When("I run {string} in the container") do |command|
  allow(@client).to receive(:execute).and_return({ stdout: "hello world\n" })
  @result = @container.run(command)
end

Then("the command should execute successfully") do
  expect(@result).to be_a(Hash)
  expect(@result[:stdout]).not_to be_nil
end

Then("the output should contain {string}") do |expected_output|
  expect(@result[:stdout]).to include(expected_output)
end

When("I configure the container with working directory {string}") do |workdir|
  allow(@client).to receive(:execute).and_return({ stdout: "success\n" })
  @config_result = @container.config(workdir: workdir)
end

Then("the container should be configured successfully") do
  expect(@config_result).to be_a(Hash)
end

Given("I have a configured container") do
  allow(@client).to receive(:execute).with(["from", "alpine"]).and_return({ stdout: "container123\n" })
  @container = @client.from("alpine")
  allow(@client).to receive(:execute).and_return({ stdout: "success\n" })
  @container.config(workdir: "/app")
end

When("I commit the container as {string}") do |image_name|
  allow(@client).to receive(:execute).and_return({ stdout: "sha256:abc123\n" })
  @committed_image = @container.commit(image_name)
  @image_name = image_name
end

Then("a new image should be created") do
  expect(@committed_image).to be_a(Buildah::Image)
end

Then("the image should be named {string}") do |expected_name|
  expect(@committed_image.name).to eq(expected_name)
end

Given("I have a Dockerfile in the current directory") do
  # Mock the existence of a Dockerfile
  @dockerfile_content = <<~DOCKERFILE
    FROM alpine
    RUN echo "Hello World"
  DOCKERFILE
  
  # We'll mock the build process rather than creating actual files
end

When("I build an image with tag {string}") do |tag|
  allow(@client).to receive(:execute).and_return({ stdout: "Successfully built abc123\n" })
  @built_image = @client.build(".", tag: tag)
  @tag = tag
end

Then("the build should complete successfully") do
  expect(@built_image).to be_a(Buildah::Image)
end

Then("an image with tag {string} should be created") do |expected_tag|
  expect(@built_image.name).to eq(expected_tag)
end

