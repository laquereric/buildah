Feature: Buildah Client
  As a developer
  I want to use the Buildah Ruby gem
  So that I can build container images programmatically

  Background:
    Given buildah is available on the system

  Scenario: Creating a new Buildah client
    When I create a new Buildah client
    Then the client should be initialized successfully

  Scenario: Checking buildah availability
    When I check if buildah is available
    Then it should return true

  Scenario: Getting buildah version
    When I get the buildah version
    Then it should return a version string

  Scenario: Creating a container from an image
    Given I have a Buildah client
    When I create a container from "alpine" image
    Then a new container should be created
    And the container should have the correct image reference

  Scenario: Listing containers
    Given I have a Buildah client
    And I have created a container from "alpine" image
    When I list all containers
    Then the container should be in the list

  Scenario: Running a command in a container
    Given I have a Buildah client
    And I have a container from "alpine" image
    When I run "echo hello world" in the container
    Then the command should execute successfully
    And the output should contain "hello world"

  Scenario: Configuring a container
    Given I have a Buildah client
    And I have a container from "alpine" image
    When I configure the container with working directory "/app"
    Then the container should be configured successfully

  Scenario: Committing a container to an image
    Given I have a Buildah client
    And I have a configured container
    When I commit the container as "my-test-image"
    Then a new image should be created
    And the image should be named "my-test-image"

  Scenario: Building an image from Dockerfile
    Given I have a Buildah client
    And I have a Dockerfile in the current directory
    When I build an image with tag "test-build"
    Then the build should complete successfully
    And an image with tag "test-build" should be created

