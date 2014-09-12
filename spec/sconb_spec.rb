# -*- coding: utf-8 -*-
require 'spec_helper'

describe Sconb do
  it 'should have a version number' do
    Sconb::VERSION.should_not be_nil
  end

  it "should convert from .ssh/config to JSON" do
    capture(:stdout) {
      Sconb::CLI.new.invoke(:dump, [], {config: File.expand_path('../config_test', __FILE__)})
    }.should == <<OUT
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
    capture(:stdout) {
      Sconb::CLI.new.invoke(:dump, [], {config: File.expand_path('../config_test', __FILE__), all: true})
    }.should == <<OUT
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

