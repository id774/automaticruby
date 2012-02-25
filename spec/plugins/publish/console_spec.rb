require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'publish/console'

module PpInterceptor
  attr_reader :outputs

  def pp_with_store(value)
    @outputs = [] if @outputs.nil?
    @outputs << value
    pp_without_store(value)
  end
  alias_method_chain :pp, :store
end

Automatic::Plugin::PublishConsole.send(:include, PpInterceptor)

describe Automatic::Plugin::PublishConsole do
  subject {
    Automatic::Plugin::PublishConsole.new({}, AutomaticSpec.generate_pipeline{
        feed { add_link "http://github.com" }
      })
  }

  it "should call 'pp'" do
    subject.run
    subject.should have(1).outputs
  end
end

