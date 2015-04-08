module Motivosity
  class Error < ::StandardError; end
  class UnauthorizedError < Error; end
  class BalanceError < Error; end
end