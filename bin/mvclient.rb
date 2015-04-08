require 'optparse'
require_relative '../mvclient'

$options = {}

def money_str(value)
  sprintf('$%.2f', value)
end

def get_options
  OptionParser.new do |opts|
    yield opts
    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit(1)
    end
  end.parse!
end

def require_options(*required_options)
  missing = false
  required_options.each do |opt|
    unless $options[opt] && $options[opt].length > 0
      missing = true
      $stderr.puts "missing required parameter: #{opt.to_s}; use --help for more information"
    end
  end
  exit(1) if missing
end

COMMANDS = {
  login: -> {
    get_options do |opts|
      opts.banner = "login: Log in to motivosity"
      opts.on("-uUSERNAME", "--username=USERNAME", "Username (email address)") do |username|
        $options[:username] = username
      end
      opts.on("-pPASSWORD", "--password=PASSWORD", "Password") do |password|
        $options[:password] = password
      end
    end
    require_options(:username, :password)
    $client.login!($options[:username], $options[:password])
    nil
  },

  logout: -> {
    get_options do |opts|
      opts.banner = "logout: Log out of motivosity"
    end
    $client.logout!
    nil
  },

  get_balance: -> {
    get_options do |opts|
      opts.banner = "get_balance: Check balances"
    end
    response = $client.get_balance
    puts "You can give #{money_str(response['cashGiving'])}"
    puts "You can spend #{money_str(response['cashReceiving'])}"
    nil
  },

  find_users: -> {
    get_options do |opts|
      opts.banner = "find_users: Search for users by name"
      opts.on("-sTERM", "--search=TERM", "Search term (all or part of user's name)") do |search|
        $options[:search] = search
      end
      opts.on("-i", "--[no-]ignore_self", "Exclude yourself from the search results") do |is|
        $options[:ignore_self] = is
      end
    end
    require_options(:search)

    result = $client.search_for_user($options[:search], !!$options[:ignore_self])
    result.each do |name|
      puts name["fullName"]
    end
    nil
  },

  send_appreciation: -> {
    get_options do |opts|
      opts.banner = "send_appreciation: Send appreciation (and optionally a cash bonus) to another user"
      opts.on("-uUSER", "--user=USER", "Name of user to send thanks to") do |user|
        $options[:user] = user
      end
      opts.on("-aAMOUNT", "--amount=AMOUNT", "Amount to send") do |amount|
        $options[:amount] = amount
      end
      opts.on("-nNOTE", "--note=NOTE", "Attached note") do |note|
        $options[:note] = note
      end
      opts.on("-vVALUE", "--value=VALUE", "Company value") do |value|
        $options[:value] = value
      end
      opts.on("-p", "--[no-]private", "Send private thanks") do |private|
        $options[:private] = private
      end
    end
    require_options(:user)

    # find value, if given
    value = nil
    if $options[:value]
      values = $client.get_values
      value = values.detect { |value| value['name'] == $options[:value] }
      puts "Warning: No company value matches '#{$options[:value]}'" unless value
    end

    # find user
    users = $client.search_for_user($options[:user])
    if users.empty?
      puts "User '#{$options[:user]}' not found"
      exit(1)
    elsif users.size > 1
      # check for an exact match among the search results
      matching_users = users.select { |user| user['fullName'] == $options[:user] }
      if matching_users.size > 1
        puts "Multiple users match '#{$options[:user]}'; please be more specific."
        puts "Try one of #{users.map{|user| "'#{user['fullName']}'"}.join(', ')}"
        exit(1)
      else
        users = matching_users
      end
    end
    user = users[0]

    response = $client.send_appreciation! user, $options[:amount] || 0, $options[:note] || "", value, !!$options[:private]
    puts response['growl']['title'] + " " + response['growl']['content']
  }
}

def exit_with_help_message
  $stderr.puts "available commands: #{COMMANDS.keys.map(&:to_s).join(' ')} "
  $stderr.puts "use mvclient <command> --help for more information"
  exit(1)
end

exit_with_help_message if ARGV.empty?
command = COMMANDS[ARGV.shift.to_sym]
exit_with_help_message unless command

$client = Motivosity::Client.new
begin
  command.call
rescue Motivosity::Error => e
  puts e.message
  exit(e.response.code)
end
