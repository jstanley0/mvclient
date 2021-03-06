require 'json'
require 'httparty'
require 'fileutils'
require 'http-cookie'
require 'mvclient/error'

module Motivosity
  class Auth
    include HTTParty
    base_uri 'https://www.motivosity.com'
    follow_redirects false
    debug_output $stderr if ENV['MOTIVOSITY_DEBUG'].to_i == 1

    def initialize
      cookie_jar_path = File.expand_path("~/.motivosity-session")
      # make sure to create the cookie jar as read/write to current user only
      old_umask = File.umask(0177)
      begin
        @cookies = HTTP::CookieJar.new(store: :mozilla, filename: cookie_jar_path)
      ensure
        File.umask(old_umask)
      end
    end

    def login!(username, password)
      @cookies.clear
      response = self.class.post('/login.xhtml', {
          body: {
              "loginForm" => 'loginForm',
              "email" => username,
              "j_password" => password,
              "rememberMe" => 'on',
              "signInLink" => 'Sign In',
              "javax.faces.ViewState" => "3465473682371097839:-947621468971335341"
          }
      })
      raise UnauthorizedError.new("invalid username or password") unless response.code == 302
      process_response_headers(response)
      @cookies.cookies.length > 0
    end

    def logout!
      @cookies.clear
      true
    end

    def auth_headers
      { "Cookie" => HTTP::Cookie.cookie_value(@cookies.cookies) }
    end

    def process_response_headers(response)
      split_cookie_headers(response.headers['Set-Cookie']).each do |cookie_string|
        @cookies.parse(cookie_string, "https://www.motivosity.com/") do |cookie|
          cookie.max_age ||= 604800 if cookie.name == 'JSESSIONID' # force the gem to persist the session key (for one week)
          cookie
        end
      end
    end

    private

    # this is only necessary because HTTParty is stupid and it combines Set-Cookie headers into a single
    # comma-separated string which can't be naively split because there are commas in expiration dates
    def split_cookie_headers(stupidly_joined_headers)
      stupidly_joined_headers.split(/(?<!Expires=[A-Z][a-z][a-z]), /)
    end
  end
end
