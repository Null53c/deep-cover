require 'yaml'
require 'tmpdir'

module DeepCover
  module CLI
    class InstrumentedCloneReporter
      include Tools
      attr_reader :dest_path

      def initialize(gem_path)
        @root_path = File.expand_path(gem_path)
        if File.exist?(File.join(@root_path, 'Gemfile'))
          @gem_relative_path = '' # Typical case
        else
          # E.g. rails/activesupport
          @gem_relative_path = File.basename(@root_path)
          @root_path = File.dirname(@root_path)
          raise "Can't find Gemfile" unless File.exist?(File.join(@root_path, 'Gemfile'))
        end
        @dest_root = File.expand_path('~/test_deep_cover')
        @dest_root = Dir.mktmpdir("deep_cover_test") unless Dir.exist?(@dest_root)
        `rm -rf #{@dest_root}/* #{@dest_root}/.*`
        @dest_path = File.expand_path(File.join(@dest_root, @gem_relative_path))
      end

      def copy
        @copy ||= `cp -r #{@root_path}/* #{@dest_root} && cp #{@root_path}/.* #{@dest_root}`
      end

      def patch_ruby_file(ruby_file)
        content = File.read(ruby_file)
        # Insert our code after leading comments:
        content.sub!(/^((#.*\n+)*)/, '\1require "deep_cover/auto_run";')
        File.write(ruby_file, content)
      end

      def patch_main_ruby_files
        main = File.join(dest_path, 'lib/*.rb')
        Dir.glob(main).each do |main|
          puts "Patching #{main}"
          patch_ruby_file(main)
        end
      end

      def patch_gemfile
        gemfile = File.expand_path(File.join(dest_path, 'Gemfile'))
        gemfile = File.expand_path(File.join(dest_path, '..', 'Gemfile')) unless File.exist?(gemfile)
        content = File.read(gemfile)
        unless content =~ /gem 'deep-cover'/
          puts "Patching Gemfile"
          File.write(gemfile, [
            "# This file was modified by DeepCover",
            content,
            "gem 'deep-cover', path: '#{File.expand_path(__dir__ + '/../../../')}'",
            '',
          ].join("\n"))
        end
        Bundler.with_clean_env do
          `cd #{dest_path} && bundle`
        end
      end

      def patch_rubocop
        path = File.expand_path(File.join(dest_path, '.rubocop.yml'))
        return unless File.exists?(path)
        puts "Patching .rubocop.yml"
        config = YAML.load(File.read(path).gsub(/(?<!\w)lib(?!\w)/, 'lib_original'))
        ((config['AllCops'] ||= {})['Exclude'] ||= []) << 'lib/**/*'
        File.write(path, "# This file was modified by DeepCover\n" + YAML.dump(config))
      end

      def patch
        patch_gemfile
        patch_rubocop
        patch_main_ruby_files
      end

      def cover
        `cp -R #{dest_path}/lib #{dest_path}/lib_original`
        @covered_path = Tools.dump_covered_code(File.join(dest_path, 'lib_original'), File.join(dest_path, 'lib'))
      end

      def process
        Bundler.with_clean_env do
          system("cd #{dest_path} && rake", out: $stdout, err: :out)
        end
      end

      def report
        coverage = Coverage.load @covered_path
        puts coverage.report(dir: @covered_path)
      end

      def run
        copy
        cover
        patch
        process
        report
      end
    end
  end
end