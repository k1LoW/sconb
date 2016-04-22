module Net
  module SSH
    class Config
      class << self
        # Original code is Net::SSH::Config.load (https://github.com/net-ssh/net-ssh/blob/master/LICENSE.txt)
        # rubocop:disable all
        def load_with_key(path, host, options)
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

          settings
        end
      end
    end
  end
end

