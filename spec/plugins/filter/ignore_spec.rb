require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/ignore'

describe FilterIgnore do
  subject { FilterIgnore.new({'exclude' => []}, []) }

  specify {
    subject.exclude("").should be_false
  }
end
