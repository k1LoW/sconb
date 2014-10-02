require "sconb/version"
require "thor"
require "net/ssh"
require "json"

module Sconb
  class CLI < Thor

    method_option :all, :type => :boolean, :aliases => '-a', :default => false, :banner => 'dump .ssh/config and private keys.'
    method_option :config, :type => :string, :aliases => '-c', :default => '~/.ssh/config', :banner => '.ssh/config path'
    desc "dump > dump.json", "Dump .ssh/config to JSON"
    def dump(regexp_str = '.*')
      regexp = Regexp.new regexp_str
      path = options[:config]
      file = File.expand_path(path)
      configs = {}
      unless File.readable?(file)
        puts configs
        return
      end

      allconfig = config_load(path, '*')
      configs['*'] = allconfig unless allconfig.size <= 1
      IO.foreach(file) do |line|
        next if line =~ /^\s*(?:#.*)?$/
        if line =~ /^\s*(\S+)\s*=(.*)$/
          key, value = $1, $2
        else
          key, value = line.strip.split(/\s+/, 2)
        end
        next if value.nil?

        # Host
        if key.downcase == 'host'
          negative_hosts, positive_hosts = value.to_s.split(/\s+/).partition { |h| h.start_with?('!') }
          positive_hosts.each do | host |
            next if host == '*'            
            next unless host.match regexp
            config = config_load(path, host)

            allconfig.each do |key, value|
              next unless config.key? key
              config.delete key if config[key] == allconfig[key]
            end

            configs[host] = config
          end
        end

        # Match
        if key.downcase == 'match'
          match_key = key + ' ' + value
          next unless match_key.match regexp
          configs[match_key] = config_load(path, value)
        end

      end
      puts JSON.pretty_generate configs
    end

    desc "restore < dump.json > .ssh/config", "Restore .ssh/config from JSON"
    def restore()
      ssh_configs = []
      json = stdin_read
      configs = JSON.parse(json)
      configs.each do |host, config|
        ssh_config = ''
        unless host.match(/^Match /)
          ssh_config << 'Host ' + host + "\n"
        else
          ssh_config << host + "\n"
        end
        config.each do |key, value|
          next if key.downcase == 'host' || key.downcase == 'match' || key.downcase == 'identityfilecontent'
          if key.downcase == 'identityfile'
            value.each_with_index do |keyfile,i|
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

    method_option :force, :type => :boolean, :aliases => '-f', :default => false, :banner => 'force generate'
    desc "keyregen < dump.json", "Regenerate private keys from JSON"
    def keyregen()
      json = stdin_read
      configs = JSON.parse(json)
      configs.each do |host, config|
        config.each do |key, value|
          next unless key.downcase == 'identityfilecontent'
          identity_files = config['IdentityFile']
          value.each_with_index do |keycontent,i|
            identity_file = File.expand_path(identity_files[i])
            if File.exists?(identity_file) and !options[:force]
              raise Thor::Error, "Error: " + identity_files[i] + " is exists. If you want to overwrite, use --force option."
            end
            puts 'Regenerate ' + identity_files[i] + ' ...'
            File.open(identity_file, 'w') do |file|
              file.write keycontent
            end
            File.chmod(0600, identity_file)
          end
        end
      end
    end

    private
    def stdin_read()
      return $stdin.read
    end

    # Original code is Net::SSH::Config.load (https://github.com/net-ssh/net-ssh/blob/master/LICENSE.txt)
    private
    def config_load(path, host)
      settings = {}
      file = File.expand_path(path)
      return settings unless File.readable?(file)

      globals = {}
      matched_host = nil
      multi_host = []
      seen_host = false
      IO.foreach(file) do |line|
        next if line =~ /^\s*(?:#.*)?$/

        if line =~ /^\s*(\S+)\s*=(.*)$/
          key, value = $1, $2
        else
          key, value = line.strip.split(/\s+/, 2)
        end

        # silently ignore malformed entries
        next if value.nil?

        value = $1 if value =~ /^"(.*)"$/

        if key.downcase == 'host'
          # Support "Host host1 host2 hostN".
          # See http://github.com/net-ssh/net-ssh/issues#issue/6
          negative_hosts, positive_hosts = value.to_s.split(/\s+/).partition { |h| h.start_with?('!') }

          # Check for negative patterns first. If the host matches, that overrules any other positive match.
          # The host substring code is used to strip out the starting "!" so the regexp will be correct.
          negative_match = negative_hosts.select { |h| host =~ pattern2regex(h[1..-1]) }.first

          if negative_match
            matched_host = nil
          else
            matched_host = positive_hosts.select { |h| host =~ pattern2regex(h) }.first
          end
          settings[key] = host unless matched_host.nil?
          seen_host = true
        elsif key.downcase == 'match'
          if host == value
            matched_host = true
          else
            matched_host = nil
          end
          settings[key] = host unless matched_host.nil?
          seen_host = true
        elsif !seen_host
          if key.downcase == 'identityfile'
            (globals[key] ||= []) << value

            # Read IdentityFile Content
            identity_file = File.expand_path(value)
            if options[:all] and File.readable?(identity_file)
              (globals['IdentityFileContent'] ||= []) << File.open(identity_file).read
            end
          else
            globals[key] = value unless settings.key?(key)
          end
        elsif !matched_host.nil?
          if key.downcase == 'identityfile'
            (settings[key] ||= []) << value

            # Read IdentityFile Content
            identity_file = File.expand_path(value)
            if options[:all] and File.readable?(identity_file)
              (settings['IdentityFileContent'] ||= []) << File.open(identity_file).read
            end
          else
            settings[key] = value unless settings.key?(key)
          end
        end
      end

      settings = globals.merge(settings) if globals

      return settings
    end

    private
    # Original code is Net::SSH::Config.pattern2regex (https://github.com/net-ssh/net-ssh/blob/master/LICENSE.txt)
    def pattern2regex(pattern)
      pattern = "^" + pattern.to_s.gsub(/\./, "\\.").
        gsub(/\?/, '.').
        gsub(/([+\/])/, '\\\\\\0').
        gsub(/\*/, '.*') + "$"
      Regexp.new(pattern, true)
    end
  end
end
