require 'httparty'
require 'json'
require 'mvclient/auth'

module Motivosity
  class Client
    def initialize
      @auth = Auth.new
    end

    def login!(username, password)
      @auth.login! username, password
    end

    def logout!
      @auth.logout!
    end

    # supply a name or part of a name
    # returns a list of matching users
    # [{
    #  "id" => "00000000-0000-user-0000-000000000000",
    #  "fullName" => "Jane Doe",
    #  "avatarUrl" => "user-placeholder.png",
    #  }, ...]
    def search_for_user(search_term, ignore_self = true)
      get "/api/v1/usertypeahead", name: search_term, ignoreSelf: ignore_self
    end

    # returns a list of Values
    # [{
    #  "id" : "39602196-7348-cval-aa03-4f8ef9ce45b8",
    #  "name":  "Customer Experience",
    #  "description": "We aspire to create an awesome customer experience in every interaction with our product and people.",
    # ...}, ...]
    def get_values
      get "/api/v1/companyvalue"
    end

    # returns balances
    # {
    #  "cashReceiving" : 39, # money received
    #  "cashGiving"    : 10  # money available to give
    # }
    def get_balance
      get "/api/v1/usercash"
    end

    # sends appreciation to another User
    # raises BalanceError if insufficient funds exist
    def send_appreciation!(user_id, opts = {})
      params = { "toUserID" => user_id }
      params["companyValueID"] = opts[:company_value_id] if opts[:company_value_id]
      params["amount"] = opts[:amount] if opts[:amount]
      params["note"] = opts[:note] if opts[:note]
      params["privateAppreciation"] = opts[:private] || false
      put "/api/v1/user/#{user_id}/appreciation", {}, params
    end

    # returns recent announcements
    def get_announcements(page = 0)
      get "/api/v1/announcement", pageNo: page
    end

    # returns feed
    # scope is one of :team, :extended_team, :department, or :company
    def feed(scope = :team, page = 0, comment = true)
      scope_param = case scope
        when :team
          "TEAM"
        when :extended_team
          "EXTM"
        when :department
          "DEPT"
        when :company
          "CMPY"
        else
          scope.to_s
      end
      get "/api/v1/feed", scope: scope_param, page: page, comment: comment
    end

  private
    class Request
      include HTTParty
      base_uri 'https://www.motivosity.com'
      follow_redirects false
      debug_output $stderr if ENV['MOTIVOSITY_DEBUG'].to_i == 1
    end

    def request_options(path, url_params = {}, body = nil)
      { headers: @auth.auth_headers.merge({'Content-Type' => 'application/json'}), query: url_params, body: body }
    end

    def get(path, url_params = {})
      process_response(Request.get(path, request_options(path, url_params)))
    end

    def put(path, url_params = {}, form_data = {})
      process_response(Request.put(path, request_options(path, url_params, form_data.to_json)))
    end

    def process_response(response)
      @auth.process_response_headers(response) if response.headers['Set-Cookie']
      response_body = JSON.parse(response.body)
      if response.code != 200
        error = case response.code
          when 401
            UnauthorizedError.new(response.message)
          else
            if response.code == 500 && response_body["type"] == "UnbalanceCashGivingBalanceException"
              BalanceError.new("Insufficient funds")
            else
              Error.new(response.message)
            end
        end
        error.response = response
        error.response_body = response_body
        raise error
      end
      response_body
    end
  end
end
