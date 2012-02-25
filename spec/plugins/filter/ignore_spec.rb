require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/ignore'

describe Automatic::Plugin::FilterIgnore do
  context "with invalid argument for #initialize" do
    context "empty config" do
      subject { Automatic::Plugin::FilterIgnore.new({}) }
      
      specify {
        lambda { subject.exclude("") }.should raise_exception(
          NoMethodError, /undefined method `each'/)
      }
    end
  end
  
  context "with empty exclusion target" do
    subject {
      Automatic::Plugin::FilterIgnore.new({'exclude' => []}, 
        AutomaticSpec.generate_pipeline {
          feed { add_link "http://github.com" }
        })
    }
      
    describe "#exclude" do
      context "for empty link" do
        specify {
          subject.exclude("").should be_false
        }
      end
      
      context "for existent link" do
        specify {
          subject.exclude("http://github.com").should be_false
        }
      end
    end

    describe "#run" do
      its(:run) { should have(1).feeds }
    end
  end  
  
  context "with exclusion target 'github'" do
    subject {
      Automatic::Plugin::FilterIgnore.new({'exclude' => ["github"]},
        AutomaticSpec.generate_pipeline {
          feed { add_link "http://github.com" }
          feed { add_link "http://google.com" }
        })
    }
    
    describe "#exclude" do
      context "for empty link" do
        specify {
          subject.exclude("").should be_false
        }
      end
      
      context "for the link including exclusion targed" do
        specify {
          subject.exclude("http://github.com").should be_true
        }
      end
    end

    describe "#run" do
      its(:run) { should have(1).feeds }
    end
  end  
end
