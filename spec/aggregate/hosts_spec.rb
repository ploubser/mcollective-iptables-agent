#!/usr/bin/env ruby

require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'aggregate', 'hosts.rb')

module MCollective
  class Aggregate
    describe Hosts do
      describe '#startup_hook' do
        it 'should setup the correct result hash' do
          result = Hosts.new(:test, [], nil, :test_action)
          result.result.should == {:value => {}, :type => :collection, :output => 'test'}
        end

        it 'should set a non default aggregate format' do
          result = Hosts.new(:test, [], "%s%s", :test_action)
          result.aggregate_format.should == "%s%s"
        end
      end

      describe '#process_result' do
        it 'should add a hostname to the correct result hash entry' do
          reply = mock
          reply.stubs(:results).returns({:sender => 'a.com'})
          result = Hosts.new(:test, [], nil, :test_action)
          result.process_result('1', reply)
          result.result[:value].should == {'1' => ['a.com']}
        end
      end

      describe '#summarize' do
        it 'should turn the hosts array into a string and return the result class' do
          result_obj = mock
          reply = mock

          result_obj.stubs(:new).returns(:success)
          reply_order = sequence('reply_order')
          reply.expects(:results).returns({:sender => 'a.com'})
          reply.expects(:results).returns({:sender => 'b.com'})
          reply.expects(:results).returns({:sender => 'c.com'})

          result = Hosts.new(:test, [], nil, :test_action)
          result.process_result('1', reply)
          result.process_result('1', reply)
          result.process_result('2', reply)
          result.stubs(:result_class).returns(result_obj)

          result.summarize.should == :success
          result.result[:value].should == {"2"=>"a.com", "1"=>"c.com,b.com"}
        end
      end
    end
  end
end
