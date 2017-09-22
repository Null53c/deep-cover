require 'parser'
require 'parser/current'
require 'pry'
require 'pathname'

module DeepCover
  # A collection of CoveredCode
  class Coverage
    def initialize(**options)
      @covered_code = {}
      @options = options
    end

    def line_coverage(filename)
      covered_code(filename).line_coverage
    end

    def covered_code(path)
      raise 'path must be an absolute path' unless Pathname.new(path).absolute?
      @covered_code[path] ||= CoveredCode.new(path: path, **@options)
    end
  end
end
