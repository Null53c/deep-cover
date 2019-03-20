# frozen_string_literal: true

class RSpec::Core::ExampleGroup
  def self.each_code_examples(name:, glob: "#{__dir__}/char_cover/*.rb", max_files: nil, &block)
    Dir.glob(glob).sort.each_with_index do |fn, i|
      break if max_files && i >= max_files

      index = 0
      spec = File.basename(fn, '.rb')
      describe spec do
        example_groups = DeepCover::Specs::AnnotatedExamplesParser.process(File.read(fn).lines)
        example_groups.each do |section, examples|
          context(section || '(General)') do
            examples.each do |title, (lines, lineno)|
              description = [section, title].join.downcase
              infos = description.scan(/\(.*?\)/)
              msg = nil
              infos.each do |info|
                info = info[1...-1].strip
                msg = case info
                      when /^pending/i then :pending
                      when /^skip/i then :skip
                      when /^#{name}_pending/i then :pending
                      when /^ruby 2\.(\d)\+/i
                        :skip if RUBY_VERSION < "2.#{Regexp.last_match(1)}.0"
                      when /^ruby <2\.(\d)/i
                        :skip if RUBY_VERSION >= "2.#{Regexp.last_match(1)}.0"
                      when /^!jruby/i
                        :skip if RUBY_PLATFORM == 'java'
                      when /^jruby (\d(?:\.\d)+)\+/i
                        :skip if RUBY_PLATFORM == 'java' && JRUBY_VERSION < Regexp.last_match(1)
                      when /^!truffleruby/i
                        :skip if DeepCover.on_truffleruby?
                      when /^#/
                      when /^tag/
                      when ''
                      when /^\w+_pending/i
                      else
                        raise "unexpected '(pattern' in section/title: #{description}. Use (# #{info}) if you want it ignored."
                      end
                break if msg
              end
              if [section, title].join =~ /\(tag: (\w+)/
                tag = Regexp.last_match(1).to_sym
              end
              send(msg || :it, "#{title || '(General)'} [#{spec} #{index}]", *tag) { self.instance_exec(fn, lines, lineno, &block) }
              index += 1
            end
          end
        end
      end
    end
  end
end
