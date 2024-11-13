require 'nokogiri'
require 'intacct_ruby/exceptions/function_failure_exception'

module IntacctRuby
  # Wraps an XML API response, throwing an exception if the call was unsucessful
  #
  # This class *can* be instantiated on its own, but only in cases where the
  # contents of the response (e.g. generated keys, query results) aren't
  # important.
  #
  # If, for example, a key returned needs to be extracted from the response,
  # extend this class and add methods that access whatever data is required.
  class Response
    attr_reader :response_body

    #delegate_missing_to :response_body

    delegate :to_xml, to: :response_body

    def initialize(http_response)
      @response_body = Nokogiri::XML(http_response.body)

      # raises an error unless the response is in the 2xx range.
      http_response.value

      # in case the response is a success, but one of the included functions
      # failed and the transaction was rolled back
      raise_function_errors unless transaction_successful?
    end

    def to_json
      @to_json ||= to_hash.to_json
    end

    def to_hash
      @to_hash ||= Hash.from_xml(to_xml)
    end

    def data
      @data ||= JSON.parse(to_json, object_class: OpenStruct)
    end

    def result
      data&.response&.operation&.result
    end

    def function_errors
      @function_errors ||= @response_body.xpath('//error/description2')
                                         .map(&:text)
    end

    private

    def transaction_successful?
      function_errors.none?
    end

    def raise_function_errors
      raise Exceptions::FunctionFailureException.new(function_errors.join("\n"), source: self)
    end
  end
end
