#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  describe 'Iptables Application' do
    before do
      application_file = File.join(File.dirname(__FILE__), '../../', 'application', 'iptables.rb')
      @util = MCollective::Test::ApplicationTest.new("iptables", :application_file => application_file)
      @app = @util.plugin
    end

    describe '#application_description' do
      it 'should have a description set' do
        @app.should have_a_description
      end
    end

    describe '#post_option_parser' do
    end

    describe '#validate_configuration' do
      it 'should fal if an unknown command is supplied' do
        expect{
          @app.validate_configuration({:command => 'fail'})
        }.to raise_error 'Command should be one of block, unblock or isblocked'
      end

      it 'should fail if ipaddress is not a valid ipv4 address' do
        MCollective::Validator.expects(:validate).raises(ValidatorError)
        expect{
          @app.validate_configuration({:ipaddress => 'foo', :command => 'block'})
        }.to raise_error ValidatorError
      end
    end

    describe '#main' do
      let(:rpcclient){mock}

      before do
        @app.expects(:rpcclient).with('iptables').returns(rpcclient)
      end

      it 'should call the rpc command quietly if silent is set' do
        @app.stubs(:configuration).returns({:silent => true,
                                            :command => 'block',
                                            :ipaddress => '1.2.3.4',
                                            :process_results => false})
        rpcclient.expects(:send).returns('block')
        @app.expects(:puts).with('Sent request block')
        @app.main
      end

      it 'should call the rpc command with output if silent is not set if verbose is true' do
        reply = [{:sender => 'localhost',
                 :statusmsg => 'OK',
                 :data => {:output => 'unblocked'}}]
        @app.stubs(:configuration).returns({:silent => false,
                                            :command => 'unblock',
                                            :ipaddress => '1.2.3.4',
                                            :process_results => false})

        rpcclient.stubs(:verbose).returns(true)
        rpcclient.expects(:send).returns(reply)
        @app.expects(:printf).with("%-40s %s\n", 'localhost', 'OK')
        @app.expects(:puts).with("\t\tunblocked")
        @app.main
      end

      it 'should call the rpc command with output if silent is not set and if verbose is false' do
        reply = [{:sender => 'localhost',
                 :statusmsg => 'OK',
                 :data => {:output => 'isblocked'}}]
        @app.stubs(:configuration).returns({:silent => false,
                                            :command => 'unblock',
                                            :ipaddress => '1.2.3.4',
                                            :process_results => false})

        rpcclient.stubs(:verbose).returns(true)
        rpcclient.expects(:send).returns(reply)
        @app.expects(:printf).with("%-40s %s\n", 'localhost', 'OK')
        @app.main
      end
    end
  end
end
