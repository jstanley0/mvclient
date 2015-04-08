require 'json'
require 'httparty'
require 'fileutils'
require_relative 'error'

module Motivosity
  class Auth
    include HTTParty
    base_uri 'https://www.motivosity.com'
    follow_redirects false

    def initialize(user, password)
      return if check_saved_session
      raise UnauthorizedError.new("no username given") unless user && user.length > 0
      response = self.class.post('/login.xhtml', {
          body: {
              "loginForm" => 'loginForm',
              "email" => user,
              "j_password" => password,
              "rememberMe" => 'on',
              "signInLink" => 'Sign In',
              "javax.faces.ViewState" => "3465473682371097839:-947621468971335341"
          }
      })
      raise UnauthorizedError.new("invalid username or password") unless response.code == 302
      parse_cookies(response.headers['Set-Cookie'])
      save_session
    end

    def login_by_json!(json_file)
      creds = JSON.parse(File.read(json_file))
      login!(creds['email'], creds['password'])
    end

    def auth_headers
      { "Cookie" => @cookies.map { |k, v| "#{k}=#{v}" }.join("; ") }
    end

  private
    def parse_cookies(headers)
      @cookies = {}
      # stupid HTTParty joins multiple Set-Cookie headers with ", ", which is ambiguous due to dates
      # so just filter out the days of the week ("Mon, ") so we can separate the cookies
      headers.gsub(/(Mon|Tue|Wed|Thu|Fri|Sat|Sun), /, '').split(', ').each do |cookie_header|
        cookie_values = cookie_header.split("; ")
        next unless cookie_values.length >= 1
        key, value = cookie_values[0].split('=')
        @cookies[key] = value
      end
    end

    def save_session
      File.write(session_file, @cookies.to_json)
    end

    def check_saved_session
      return false unless File.exists?(session_file)
      @cookies = JSON.parse(File.read(session_file))
      # if the session file is over an hour old, test the stored auth and touch or delete the file
      if ((Time.now - File.mtime(session_file)) > 3600)
        response = self.class.get '/api/v1/usercash', { headers: auth_headers }
        if response.code == 200
          FileUtils.touch session_file
          return true
        else
          File.unlink session_file
          return false
        end
      end
      true
    end

    def session_file
      @session_file ||= File.expand_path("~/.mvclient-session")
    end
  end
end
