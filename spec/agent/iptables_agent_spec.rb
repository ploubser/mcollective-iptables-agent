#!/usr/bin/env rspec

require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'agent', 'iptables.rb')

module MCollective
  module Agent
    describe Iptables do
      before do
        agent_file = File.join(File.dirname(__FILE__), '../../', 'agent', 'iptables.rb')
        @agent = MCollective::Test::LocalAgentTest.new('iptables', :agent_file => agent_file).plugin
      end

      let(:shell){mock}

      describe '#block' do
        it 'should not block an already blocked ip address' do
          Iptables.expects(:isblocked?).with('1.2.3.4').returns('true')
          Shell.expects(:new).never
          result = @agent.call(:block, :ipaddr => '1.2.3.4')
          result.should be_aborted_error
        end

        it 'should fail if ip address cannot be blocked' do
          Iptables.expects(:isblocked?).with('1.2.3.4').returns(false).twice
          Shell.expects(:new).returns(shell).twice
          shell.expects(:runcommand).twice

          result = @agent.call(:block, :ipaddr => '1.2.3.4')
          result.should be_aborted_error
        end

        it 'should block an ip address' do
          block_check = sequence('block_check')
          Iptables.expects(:isblocked?).with('1.2.3.4').returns(false).in_sequence(block_check)
          Iptables.expects(:isblocked?).with('1.2.3.4').returns(true).in_sequence(block_check)
          Shell.expects(:new).returns(shell).twice
          shell.expects(:runcommand).twice

          result = @agent.call(:block, :ipaddr => '1.2.3.4')
          result.should be_successful
        end
      end

      describe '#unblock' do
        it 'should fail if the ip address was not blocked' do
          Iptables.expects(:isblocked?).returns(false)
          result = @agent.call(:unblock, :ipaddr => '1.2.3.4')
          result.should be_aborted_error
        end

        it 'should fail if ip address cannot be unblocked' do
          Iptables.expects(:isblocked?).with('1.2.3.4').returns(true).twice
          result = @agent.call(:unblock, :ipaddr => '1.2.3.4')
          result.should be_aborted_error
        end

        it 'should unblock an ip address' do
          unblock_check = sequence('unblock_check')
          Iptables.expects(:isblocked?).with('1.2.3.4').returns(true).in_sequence(unblock_check)
          Iptables.expects(:isblocked?).with('1.2.3.4').returns(false).in_sequence(unblock_check)
          Shell.expects(:new).returns(shell).twice
          shell.expects(:runcommand).twice

          result = @agent.call(:unblock, :ipaddr => '1.2.3.4')
          result.should be_successful
        end
      end

      describe '#isblocked' do
        it 'should display the correct output if an ip is blocked' do
          Iptables.expects(:isblocked?).returns(true)
          result = @agent.call(:isblocked, :ipaddr => '1.2.3.4')
          result.should be_successful
          result.should have_data_items(:output => '1.2.3.4 is blocked')
        end

        it 'should display the correct output if an ip is not blocked' do
          Iptables.expects(:isblocked?).returns(false)
          result = @agent.call(:isblocked, :ipaddr => '1.2.3.4')
          result.should be_successful
          result.should have_data_items(:output => '1.2.3.4 is not blocked')
        end
      end

      describe '#listblocked' do
        it 'should display an empty array if nothing is blocked' do
          Shell.expects(:new).returns(shell)
          shell.expects(:runcommand)
          result = @agent.call(:listblocked)
          result.should be_successful
          result.should have_data_items(:blocked => [])
        end

        it 'should list the blocked ip addresses' do
          split_order = sequence('split_order')
          String.any_instance.expects(:split).returns("DROP       all  --  1.2.3.4\nDROP       all  --  4.3.2.1").in_sequence(split_order)
          String.any_instance.expects(:split).returns(['', '', '', '1.2.3.4']).in_sequence(split_order)
          String.any_instance.expects(:split).returns(['', '', '', '4.3.2.1']).in_sequence(split_order)
          result = @agent.call(:listblocked)
          result.should be_successful
          result.should have_data_items(:blocked => ['1.2.3.4', '4.3.2.1'])
        end
      end
    end
  end
end
