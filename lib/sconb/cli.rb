require 'thor'

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
      path = options[:config]
      puts JSON.pretty_generate(Sconb::SSHConfig.load(path, regexp_str, options))
    end

    desc 'restore < dump.json > .ssh/config', 'Restore .ssh/config from JSON'
    def restore
      ssh_configs = []
      json = stdin_read
      configs = JSON.parse(json)
      configs.each do |host, config|
        ssh_config = ''
        header = if host !~ /^Match /
                   "Host #{host}\n"
                 else
                   "#{host}\n"
                 end
        ssh_config << header
        config.each do |key, value|
          next if key.downcase == 'host' || key.downcase == 'match' || key.downcase == 'identityfilecontent'
          if key.downcase == 'identityfile'
            value.each_with_index do |keyfile, _i|
              ssh_config << "  #{key} #{keyfile}\n"
            end
          else
            ssh_config << "  #{key} #{value}\n"
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
