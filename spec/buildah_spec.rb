# frozen_string_literal: true

RSpec.describe Buildah do
  it "has a version number" do
    expect(Buildah::VERSION).not_to be nil
  end

  describe ".new" do
    it "creates a new client instance" do
      allow(Buildah::Client).to receive(:new).and_return(double("client"))
      client = Buildah.new
      expect(Buildah::Client).to have_received(:new).with({})
    end

    it "passes options to client" do
      options = { debug: true }
      allow(Buildah::Client).to receive(:new).and_return(double("client"))
      Buildah.new(options)
      expect(Buildah::Client).to have_received(:new).with(options)
    end
  end

  describe ".available?" do
    it "delegates to Client.buildah_available?" do
      allow(Buildah::Client).to receive(:buildah_available?).and_return(true)
      result = Buildah.available?
      expect(result).to be true
      expect(Buildah::Client).to have_received(:buildah_available?)
    end
  end

  describe ".version" do
    it "delegates to Client.buildah_version" do
      allow(Buildah::Client).to receive(:buildah_version).and_return("1.23.0")
      result = Buildah.version
      expect(result).to eq("1.23.0")
      expect(Buildah::Client).to have_received(:buildah_version)
    end
  end
end
