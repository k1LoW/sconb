module Sconb
  module SSHConfig
    class << self
      def load(regexp_str, options)
        @options = options
        @regexp = Regexp.new(regexp_str)
        @path = @options[:config]
        file = File.expand_path(@path)
        @configs = {}
        return @configs unless File.readable?(file)

        @allconfig = Net::SSH::Config.sconb_load(@path, '*', @options)
        @configs['*'] = @allconfig unless @allconfig.size <= 1
        IO.foreach(file) do |line|
          parse(line)
        end
        @configs
      end

      private

      def parse(line)
        return if line =~ /^\s*(?:#.*)?$/
        if line =~ /^\s*(\S+)\s*=(.*)$/
          key = Regexp.last_match[1]
          value = Regexp.last_match[2]
        else
          key, value = line.strip.split(/\s+/, 2)
        end
        return if value.nil?

        # Host
        if key.downcase == 'host'
          negative_hosts, positive_hosts = value.to_s.split(/\s+/).partition { |h| h.start_with?('!') }
          positive_hosts.each do |host|
            next if host == '*'
            next unless host.match @regexp
            config = Net::SSH::Config.sconb_load(@path, host, @options)

            @allconfig.each do |k, _v|
              next unless config.key? k
              config.delete k if config[k] == @allconfig[k]
            end

            @configs[host] = config
          end
        end

        # Match
        if key.downcase == 'match'
          match_key = key + ' ' + value
          return unless match_key.match @regexp
          @configs[match_key] = Net::SSH::Config.sconb_load(@path, value, @options)
        end
      end
    end
  end
end
