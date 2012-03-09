module Automatic::Plugin
  class StoreMock
    def initialize(config, pipeline = [])
      @config = config
      @pipeline = pipeline
    end

    def run
      return @pipeline[0]
    end
  end
end
