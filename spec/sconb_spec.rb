# -*- coding: utf-8 -*-
require 'spec_helper'

describe Sconb do
  context '`dump` command' do

    it "should convert from .ssh/config to JSON" do
      expect(capture(:stdout) {
               Sconb::CLI.new.invoke(:dump, [], {config: File.expand_path('../config_test', __FILE__)})
             }).to eq <<OUT
{
  "github.com": {
    "Host": "github.com",
    "User": "git",
    "Port": "22",
    "Hostname": "github.com",
    "IdentityFile": [
      "spec/github_rsa"
    ],
    "TCPKeepAlive": "yes",
    "IdentitiesOnly": "yes"
  }
}
OUT
    end

    it "should convert from multi config to JSON" do
      expect(capture(:stdout) {
               Sconb::CLI.new.invoke(:dump, [], {config: File.expand_path('../config_test_multi', __FILE__)})
             }).to eq <<OUT
{
  "github.com": {
    "Host": "github.com",
    "User": "git",
    "Port": "22",
    "Hostname": "github.com",
    "IdentityFile": [
      "spec/github_rsa"
    ],
    "TCPKeepAlive": "yes",
    "IdentitiesOnly": "yes"
  },
  "Match exec \\"nmcli connection status id <ap-name> 2> /dev/null\\"": {
    "Match": "exec \\"nmcli connection status id <ap-name> 2> /dev/null\\"",
    "ProxyCommand": "ssh -W %h:%p github.com"
  },
  "gist": {
    "Host": "gist",
    "User": "git",
    "Port": "22",
    "Hostname": "gist.github.com",
    "IdentityFile": [
      "spec/github_rsa"
    ],
    "TCPKeepAlive": "yes",
    "IdentitiesOnly": "yes"
  }
}
OUT
    end

    it "should convert from .ssh/config to JSON with private keys" do
      expect(capture(:stdout) {
               Sconb::CLI.new.invoke(:dump, [], {config: File.expand_path('../config_test', __FILE__), all: true})
             }).to eq <<OUT
{
  "github.com": {
    "Host": "github.com",
    "User": "git",
    "Port": "22",
    "Hostname": "github.com",
    "IdentityFile": [
      "spec/github_rsa"
    ],
    "IdentityFileContent": [
      "1234567890"
    ],
    "TCPKeepAlive": "yes",
    "IdentitiesOnly": "yes"
  }
}
OUT
    end
  end

  context '`restore` command' do
    before do
      @cli = Sconb::CLI.new
      allow(@cli).to receive_messages(:stdin_read => <<INN
{
  "github.com": {
    "Host": "github.com",
    "User": "git",
    "Port": "22",
    "Hostname": "github.com",
    "IdentityFile": [
      "spec/github_rsa"
    ],
    "IdentityFileContent": [
      "1234567890"
    ],
    "TCPKeepAlive": "yes",
    "IdentitiesOnly": "yes"
  },
  "gist": {
    "Host": "gist",
    "User": "git",
    "Port": "22",
    "Hostname": "gist.github.com",
    "IdentityFile": [
      "spec/github_rsa"
    ],
    "IdentityFileContent": [
      "1234567890"
    ],
    "TCPKeepAlive": "yes",
    "IdentitiesOnly": "yes"
  },
  "Match exec \\"nmcli connection status id <ap-name> 2> /dev/null\\"": {
    "Match": "exec \\"nmcli connection status id <ap-name> 2> /dev/null\\"",
    "ProxyCommand": "ssh -W %h:%p github.com"
  }
}
INN
)
    end
    it "should convert from JSON to config" do
      expect(capture(:stdout) {
               @cli.restore
             }).to eq <<OUT
Host github.com
  User git
  Port 22
  Hostname github.com
  IdentityFile spec/github_rsa
  TCPKeepAlive yes
  IdentitiesOnly yes

Host gist
  User git
  Port 22
  Hostname gist.github.com
  IdentityFile spec/github_rsa
  TCPKeepAlive yes
  IdentitiesOnly yes

Match exec "nmcli connection status id <ap-name> 2> /dev/null"
  ProxyCommand ssh -W %h:%p github.com
OUT
    end
  end
end
