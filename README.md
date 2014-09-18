# Sconb [![Gem Version](https://badge.fury.io/rb/sconb.svg)](http://badge.fury.io/rb/sconb) [![Build Status](https://travis-ci.org/k1LoW/sconb.svg?branch=master)](https://travis-ci.org/k1LoW/sconb) [![Coverage Status](https://coveralls.io/repos/k1LoW/sconb/badge.png)](https://coveralls.io/r/k1LoW/sconb) [![Dependency Status](https://gemnasium.com/k1LoW/sconb.svg)](https://gemnasium.com/k1LoW/sconb)

Ssh CONfig Buckup tool.

## Installation

Install it yourself as:

    $ gem install sconb

## Usage

    $ sconb

    Commands:
      sconb dump > dump.json                   # Dump .ssh/config to JSON
      sconb help [COMMAND]                     # Describe available commands or one specific command
      sconb keyregen < dump.json               # Regenerate private keys from JSON
      sconb restore < dump.json > .ssh/config  # Restore .ssh/config from JSON

### Backup .ssh/config to JSON

    $ sconb dump > ssh_config.json

### Restore .ssh/config from JSON

    $ sconb restore < ssh_config.json > ~/.ssh/config

### Backup .ssh/config with private keys to JSON

    $ sconb dump --all > ssh_config.json

### Regenerate private keys from JSON

    $ sconb keyregen < ssh_config.json

## Advanced Tips

### Select host

Dump github.com config only.

    $ sconb dump | jq '{"github.com"}' > github.json

And append github.com config to .ssh/config

    $ sconb restore < github.json >> ~/.ssh/config

### Merge config

    $ jq -s '.[0] + .[1]' a.json b.json | sconb restore > ~/.ssh/config

## Contributing

1. Fork it ( https://github.com/k1LoW/sconb/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
