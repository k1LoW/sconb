require 'thor'
require 'json'

module Sconb
  class CLI < Thor
    option :all,
           type: :boolean,
           aliases: :a,
           default: false,
           banner: 'dump .ssh/config and private keys.'
    option :config,
           type: :string,
           aliases: :c,
           default: '~/.ssh/config',
           banner: '.ssh/config path'
    desc 'dump > dump.json', 'Dump .ssh/config to JSON'
    def dump(regexp_str = '.*')
      regexp = Regexp.new regexp_str
      path = options[:config]
      file = File.expand_path(path)
      configs = {}
      unless File.readable?(file)
        puts configs
        return
      end

      allconfig = Net::SSH::Config.sconb_load(path, '*', options)
      configs['*'] = allconfig unless allconfig.size <= 1
      IO.foreach(file) do |line|
        next if line =~ /^\s*(?:#.*)?$/
        if line =~ /^\s*(\S+)\s*=(.*)$/
          key = Regexp.last_match[1]
          value = Regexp.last_match[2]
        else
          key, value = line.strip.split(/\s+/, 2)
        end
        next if value.nil?

        # Host
        if key.downcase == 'host'
          negative_hosts, positive_hosts = value.to_s.split(/\s+/).partition { |h| h.start_with?('!') }
          positive_hosts.each do |host|
            next if host == '*'
            next unless host.match regexp
            config = Net::SSH::Config.sconb_load(path, host, options)

            allconfig.each do |k, _v|
              next unless config.key? k
              config.delete k if config[k] == allconfig[k]
            end

            configs[host] = config
          end
        end

        # Match
        if key.downcase == 'match'
          match_key = key + ' ' + value
          next unless match_key.match regexp
          configs[match_key] = Net::SSH::Config.sconb_load(path, value, options)
        end
      end
      puts JSON.pretty_generate configs
    end

    desc 'restore < dump.json > .ssh/config', 'Restore .ssh/config from JSON'
    def restore
      ssh_configs = []
      json = stdin_read
      configs = JSON.parse(json)
      configs.each do |host, config|
        ssh_config = ''
        header = if host !~ /^Match /
                   'Host ' + host + "\n"
                 else
                   host + "\n"
                 end
        ssh_config << header
        config.each do |key, value|
          next if key.downcase == 'host' || key.downcase == 'match' || key.downcase == 'identityfilecontent'
          if key.downcase == 'identityfile'
            value.each_with_index do |keyfile, _i|
              ssh_config << '  ' + key + ' ' + keyfile + "\n"
            end
          else
            ssh_config << '  ' + key + ' ' + value + "\n"
          end
        end
        ssh_configs.push ssh_config
      end
      puts ssh_configs.join("\n")
    end

    option :force,
           type: :boolean,
           aliases: :f,
           default: false,
           banner: 'force generate'
    desc 'keyregen < dump.json', 'Regenerate private keys from JSON'
    def keyregen
      json = stdin_read
      configs = JSON.parse(json)
      configs.each do |_host, config|
        config.each do |key, value|
          next unless key.downcase == 'identityfilecontent'
          identity_files = config['IdentityFile']
          value.each_with_index do |keycontent, i|
            identity_file = File.expand_path(identity_files[i])
            if File.exist?(identity_file) && !options[:force]
              raise Thor::Error, "Error: #{identity_files[i]} is exists. If you want to overwrite, use --force option."
            end
            puts "Regenerate #{identity_files[i]} ..."
            File.open(identity_file, 'w') do |file|
              file.write keycontent
            end
            File.chmod(0600, identity_file)
          end
        end
      end
    end

    private

    def stdin_read
      $stdin.read
    end
  end
end
