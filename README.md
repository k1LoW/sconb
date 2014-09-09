# Sconb

Ssh CONfig Buckup tool.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sconb'
```

And then execute:

    $ bundle

## Usage

### Backup .ssh/config to JSON

    $ sconb dump > ssh_config.json

### Restore .ssh/config from JSON

    $ sconb restore < ssh_config.json > ~/.ssh/config

### Backup .ssh/config with private keys to JSON

    $ sconb dump --all > ssh_config.json

### Regenerate private keys from JSON

    $ sconb keyregen < ssh_config.json

## Contributing

1. Fork it ( https://github.com/[my-github-username]/sconb/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
