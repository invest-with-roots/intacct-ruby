module IntacctRuby
  module Exceptions
    class FunctionFailureException < StandardError;
      attr_reader :source

      def initialize(msg = nil, source: nil)
        @source = source

        super(msg)
      end
    end
  end
end
