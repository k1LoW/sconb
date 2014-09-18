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
OUT
    end
  end
end
