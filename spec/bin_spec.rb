# frozen_string_literal: true

require_relative 'spec_helper'


RSpec.describe 'bin/cov', :slow do
  params_sets = ['case 0', 'exception_ensure 0', 'if 0']

  params_sets.each do |params_set|
    it "run `bin/cov #{params_set}` successfully" do
      command_success = clean_env_system({'DISABLE_PRY' => '1'}, "bin/cov #{params_set}", in: File::NULL, out: File::NULL, err: File::NULL)
      command_success.should be true
    end
  end
end
