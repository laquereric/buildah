# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-09-07

### Added

#### Core Features
- **Buildah::Client**: Main interface for buildah operations with comprehensive command execution
- **Buildah::Container**: Complete container lifecycle management (create, run, configure, commit, remove)
- **Buildah::Image**: Image operations including pull, push, tag, remove, inspect, and history
- **Buildah::Builder**: Building images from Containerfiles/Dockerfiles with extensive build options
- **Buildah::Config**: Configuration management for containers and images

#### Container Operations
- Create containers from images or scratch
- Run commands inside containers with various options (user, workdir, env)
- Add and copy files to containers with ownership control
- Mount and unmount container filesystems
- Configure containers (cmd, entrypoint, env, ports, volumes, etc.)
- Commit containers to create new images
- List, inspect, and remove containers

#### Image Operations
- Pull images from registries with authentication support
- Push images to registries with credentials
- Tag images with new names
- Remove images with force option
- Inspect image configuration and metadata
- Get image layer history
- List all available images

#### Build Operations
- Build images from Containerfiles/Dockerfiles
- Support for build arguments and target stages
- Multi-architecture builds
- Cache control options
- Output format selection (OCI/Docker)
- Layer and squashing options
- Network and volume configuration during builds

#### Error Handling
- **Buildah::Error**: Base error class
- **Buildah::BuildahNotFoundError**: Buildah command not found
- **Buildah::CommandError**: Command execution failures with exit codes and stderr
- **Buildah::ContainerError**: Container operation failures
- **Buildah::ImageError**: Image operation failures
- **Buildah::BuildError**: Build operation failures
- **Buildah::ConfigError**: Configuration operation failures
- **Buildah::ArgumentError**: Invalid argument errors

#### Configuration & Flexibility
- Custom buildah executable paths
- Environment variable configuration
- Debug mode for command tracing
- Comprehensive option support for all operations
- JSON parsing for structured command outputs

#### Testing & Documentation
- Comprehensive RSpec test suite with mocking
- Cucumber BDD features for integration testing
- Extensive README with usage examples
- API documentation with YARD comments
- RuboCop linting configuration

#### Development Tools
- Bundler gem structure with proper gemspec
- Rake tasks for testing and linting
- Git integration and ignore patterns
- Console script for interactive development
- Setup script for easy development environment

### Technical Details
- Ruby 3.0+ compatibility
- Uses Open3 for secure command execution
- JSON parsing for structured buildah outputs
- Comprehensive error handling and reporting
- Object-oriented design with clear separation of concerns
- Extensive test coverage with both unit and integration tests
