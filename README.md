# mvclient

This is a minimal client wrapper for the (not yet published!) Motivosity API. It allows you to check balances,
send money, and retrieve the announcements and news feed. A limited [command-line tool](#command-line-tool) is also provided.

## client library

### Installation

```
gem install mvclient
```

### Instantiation

```ruby
require 'mvclient'
@client = Motivosity::Client.new
```

### Log in

```ruby
@client.login! 'username@example.com', 'correct horse battery staple'
```
Note that session information is stored in `~/.motivosity-session`, so it is not necessary to log in every time you create a Motivosity::Client object.  This is useful for command-line operation (see below).

### Log out

```ruby
@client.logout! 
```
This will clear stored session information in `~/.motivosity-session`

### Search for user

```ruby
@client.search_for_user(search_term, ignore_self)
```
returns a list of matching users
```ruby
[{
 "id" => "00000000-0000-user-0000-000000000000",
 "fullName" => "Jane Doe",
 "avatarUrl" => "user-placeholder.png",
 }, ...]
```

### Get company values

```ruby
@client.get_values
```
returns a list of company values
```ruby
[{
 "id" : "39602196-7348-cval-aa03-4f8ef9ce45b8",
 "name":  "Customer Experience",
 "description": "We aspire to create an awesome customer experience in every interaction with our product and people.",
 ...}, ...]
```

### Get balances

```ruby
@client.get_balances
```
returns balance information
```ruby
{
 "cashReceiving" : 39, # money received
 "cashGiving"    : 10  # money available to give
}
```

### Send appreciation

```ruby
@client.send_appreciation! user_id, amount: 1.00, note: "Here, have a dollar", company_value_id: value_id, private: false
```

### Get announcements

```ruby
@client.get_announcements(page_no) # 0-based
```

### Get news feed
```ruby
# scope is one of :team, :extended_team, :department, or :company
@client.feed(:team, page_no) # 0-based
```

<a id="command-line-tool"></a>
## command-line tool

A command-line tool is also provided in `bin/mvclient`.  Use `--help` to receive usage information.

### Log in

```
mvclient login -u "user@example.com" -p "correct horse battery staple"
```
If either argument is omitted, you will be prompted to enter it.

### Log out

```
mvclient logout
```

### Get balance

```
mvclient get_balance
```
Example output:
```
You can give $7.00
You can spend $21.00
```

### Send appreciation

```
mvclient send_appreciation -u "Jane Doe" -a "1.00" -n "Note" -v "Customer Experience" 
```
The `-u` option accepts either a user ID or a name. Partial names are acceptable, but the call will fail unless exactly one name matches.

Example output:
```
Success! Jane Doe has received your appreciation.
```

### Debugging

Set `MOTIVOSITY_DEBUG=1` to enable logging of all communication with Motivosity to stderr