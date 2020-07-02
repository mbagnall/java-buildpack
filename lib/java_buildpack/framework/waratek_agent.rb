# frozen_string_literal: true

# Cloud Foundry Java Buildpack
# Copyright 2013-2020 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'java_buildpack/component/base_component'
require 'java_buildpack/component/versioned_dependency_component'
require 'java_buildpack/framework'

module JavaBuildpack
  module Framework

    # Encapsulates the functionality for enabling Waratek Secure support.
    class WaratekSecure < JavaBuildpack::Component::VersionedDependencyComponent

      def initialize(context, &version_validator)
        super(context, &version_validator)
        @component_name = 'Waratek Secure'
      end

      # Determines if the application requires Waratek.
      def detect
        waratek_required? ? process_config : nil
      end

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        download_zip false
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release
        java_opts = @droplet.java_opts

        java_opts
          .add_javaagent(agent_jar)
          .add_system_property('com.waratek.ContainerHome', DEFAULT_JAVA)
          .add_system_property('com.waratek.WaratekProperties', waratek_props_file)

        export_all_properties(java_opts)
      end


    private

    # Name of Waratek Agent jar in the download
    WARATEK_JAR = 'waratek.jar'.freeze
    # Subdirectory under the app directory into which we place the download and unpack
    WARATEK_DIR = '.waratek'.freeze
    # Default location of Java
    DEFAULT_JAVA = '.java'.freeze

    # @return [Boolean]  true if the app is requesting Waratek by setting an env variable.
    # value is set in "config/waratek_secure_agent.yml"
    def waratek_required?
      @environment['waratek_required'] && @configuration['enabled']
    end

    # @return [Boolean] if the value of the env variable 'waratek_properties' is set by the app, otherwise nil
    # e.g. ".waratek/conf_1/waratek.properties" (in App's manifest.yml)
    #def waratek_properties_supplied?
    #  @environment['waratek_properties']
    #end

    def process_config
      @uri = @configuration['uri']
      @version = @configuration['version']

      # The Agent doesn't yet specify the URI or the Repository Root. At present, it's
      # the application that defines the location of the Agent zip file to download
      if @uri.nil?
        @uri = @environment['waratek_treasure']
      end

      @version.nil? ? nil : '19.0.0'
    end

    def waratek_props_file
      @droplet.sandbox + '.waratek/conf_1/waratek.properties'
    end

    def agent_jar
      #@droplet.sandbox + 'agent/waratek.jar'
      @droplet.sandbox + '.waratek/agent/waratek.jar'
    end

  end
end
