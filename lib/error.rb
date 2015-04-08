module Motivosity
  class Error < ::StandardError
    attr_accessor :response, :response_body
  end
  class UnauthorizedError < Error; end
  class BalanceError < Error; end
end