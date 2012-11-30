#!/usr/bin/env rspec

require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'agent', 'iptables.rb')
require File.join(File.dirname(__FILE__), '../../', 'data', 'iptables_data.rb')

module MCollective
  module Data
    describe Iptables_data do
      describe '#query_data' do
        before do
          @ddl = mock
          @ddl.stubs(:meta).returns({:timeout => 1})
          DDL.stubs(:new).returns(@ddl)
          @plugin = Iptables_data.new
        end

        it "it should return 'true' if ip is blocked" do
          Agent::Iptables.expects(:isblocked?).returns(true)
          @plugin.query_data('1.2.3.4').should == 'true'
        end

        it "should return 'false' if the ip is not blocked" do
          Agent::Iptables.expects(:isblocked?).returns(false)
          @plugin.query_data('1.2.3.4').should == 'false'
        end
      end
    end
  end
end

