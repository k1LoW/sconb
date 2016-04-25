module Sconb
  module SSHConfig
    class << self
      def load(path, regexp_str = '.*', options = [])
        file = File.expand_path(path)
        content = File.readable?(file) ? File.open(file).read : nil
        parse(content, regexp_str, options)
      end

      def parse(content, regexp_str = '.*', options = [])
        @regexp = Regexp.new(regexp_str)
        @options = options
        @content = content
        @configs = {}
        return @configs if content.nil?
        @allconfig = Net::SSH::Config.parse_with_key(@content, '*', @options)
        @configs['*'] = @allconfig unless @allconfig.size <= 1
        @content.each_line do |line|
          parse_line(line)
        end
        @configs
      end

      private

      def parse_line(line)
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
            config = Net::SSH::Config.parse_with_key(@content, host, @options)

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
          @configs[match_key] = Net::SSH::Config.parse_with_key(@content, value, @options)
        end
      end
    end
  end
end
