require "spec_helper"

RSpec::Matchers.define :match_coverage do
  match do |fn|
    @our = our_coverage(fn)
    @builtin = builtin_coverage(fn)
    @our.zip(@builtin).all? do |us, ruby|
      # accept us > ruby > 0; can happen for example with `def foo(arg = this_can_run_many_times)`
      cmp = us <=> ruby
      cmp && (cmp == 0 || (cmp > 0 && ruby > 0)) # either equal, or us > ruby > 1
    end
  end
  failure_message do |fn|
    format(fn, @builtin, @our).join
  end
end

RSpec.describe DeepCover do
  Dir.glob('./spec/samples/*.rb').each do |fn|
    it "returns the same coverage for '#{File.basename(fn, '.rb')}' as the builtin one" do
      fn.should match_coverage
    end
  end
end
