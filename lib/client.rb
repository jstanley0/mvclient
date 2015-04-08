require_relative 'auth'
require_relative 'request'

module Motivosity
  class Client
    def login!(username = nil, password = nil)
      @auth = Auth.new(username, password)
    end

    # supply a name or part of a name
    # returns a list of matching users
    # [{
    #  "id" => "00000000-0000-user-0000-000000000000",
    #  "fullName" => "Jane Doe",
    #  "avatarUrl" => "user-placeholder.png",
    #  }, ...]
    def search_for_user(search_term, ignore_self = true)
      require_auth
      Request.do(:get, @auth, "/api/v1/usertypeahead", { name: search_term, ignoreSelf: ignore_self })
    end

    # returns a list of Values
    # [{
    #  "id" : "39602196-7348-cval-aa03-4f8ef9ce45b8",
    #  "name":  "Customer Experience",
    #  "description": "We aspire to create an awesome customer experience in every interaction with our product and people.",
    # ...}, ...]
    def get_values
      require_auth
      Request.do(:get, @auth, "/api/v1/companyvalue")
    end

    # returns balances
    # {
    #  "cashReceiving" : 39, # money received
    #  "cashGiving"    : 10  # money available to give
    # }
    def get_balance
      require_auth
      Request.do(:get, @auth, "/api/v1/usercash")
    end

    # sends appreciation to another User
    # raises BalanceError if insufficient funds exist
    def send_appreciation!(toUser, amount, note, company_value = nil, private = false)
      require_auth
      options = {}
      options["companyValueID"] = company_value['id'] if company_value
      options["amount"] = amount.to_s
      options["note"] = note
      options["privateAppreciation"] = private
      options["toUserID"] = toUser['id']
      options["toUserName"] = toUser['name']
      Request.do(:put, @auth, "/api/v1/user/#{toUser['id']}/appreciation", {}, options)
    end

    # returns recent announcements
    def get_announcements(page = 0)
      require_auth
      Request.do(:get, @auth, "/api/v1/announcement", { pageNo: page })
    end

    # returns feed
    # scope is one of :team, :extended_team, :department, or :company
    def feed(scope = :team, page = 0, comment = true)
      require_auth
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
      Request.do(:get, @auth, "/api/v1/feed", { scope: scope_param, page: page, comment: comment })
    end

    private

    def require_auth
      raise UnauthorizedError.new('not logged in') unless @auth
    end

  end
end
