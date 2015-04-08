require 'httparty'
require 'json'
require_relative 'auth'

module Motivosity
  class Request
    include HTTParty
    base_uri 'https://www.motivosity.com'
    follow_redirects false

    def self.do(method, auth, path, url_params = {}, form_data = {})
      options = {}
      options[:headers] = auth.auth_headers
      options[:query] = url_params
      options[:body] = form_data
      response = case method
        when :get
          get path, options
        when :put
          put path, options
        when :post
          post path, options
        else
          raise Error.new("unsupported method #{method.to_s}")
      end
      JSON.parse response.body
    end
  end
end
