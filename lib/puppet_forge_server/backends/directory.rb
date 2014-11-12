# -*- encoding: utf-8 -*-
#
# Copyright 2014 North Development AB
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'digest/md5'
require 'pathname'

module PuppetForgeServer::Backends
  class Directory
    include PuppetForgeServer::Utils::Archiver

    # Give highest priority to locally hosted modules
    @@PRIORITY = 0
    attr_reader :PRIORITY

    def initialize(url)
      @module_dir = url
    end

    def query_metadata(query, options = {})
      get_file_metadata("*#{query}*.tar.gz", options)
    end

    def get_metadata(author, name, options = {})
      version = options[:version] ? options[:version] : '*'
      get_file_metadata("#{author}-#{name}-#{version}.tar.gz", options)
    end

    def get_file_buffer(relative_path)
      path = File.join(File.expand_path(@module_dir), relative_path)
      File.open(path, 'r') if File.exist?(path)
    end

    private
    def read_metadata(archive_path)
      metadata_file = read_entry(archive_path, %r[[^/]+/metadata\.json$])
      JSON.parse(metadata_file)
    rescue => error
      warn "Error reading from module archive #{archive_path}: #{error}"
      return nil
    end

    def get_file_metadata(file_name, options)
      options = ({:with_checksum => true}).merge(options)
      Dir["#{@module_dir}/**/#{file_name}"].map do |path|
        checksum = Digest::MD5.hexdigest(File.read(path)) if options[:with_checksum] == true
        {
            :metadata => PuppetForgeServer::Models::Metadata.new(read_metadata(path)),
            :checksum => checksum,
            :path => "/#{Pathname.new(path).relative_path_from(Pathname.new(@module_dir))}"
        }
      end.compact
    end
  end
end