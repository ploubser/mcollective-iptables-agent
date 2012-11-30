require 'socket'

module MCollective
  module Agent
    # An agent that manipulates a chain called 'junkfilter' with iptables
    class Iptables<RPC::Agent
      action "block" do
        validate :ipaddr, :ipv4address

        blockip(request[:ipaddr])
      end

      action "unblock" do
        validate :ipaddr, :ipv4address

        unblockip(request[:ipaddr])
      end

      action "isblocked" do
        validate :ipaddr, :ipv4address

        if Iptables.isblocked?(request[:ipaddr])
          reply[:output] = "#{request[:ipaddr]} is blocked"
        else
          reply[:output] = "#{request[:ipaddr]} is not blocked"
        end
      end

      action "listblocked" do
        reply[:blocked] = listblocked
      end

      # Utility to figure out if a ip is blocked or not, just return true or false
      def self.isblocked?(ip)
        Log.debug("Checking if #{ip} is blocked with target #{Iptables.target}")

        prematches = ""
        Shell.new("/sbin/iptables -L junk_filter -n 2>&1", :stdout => prematches, :chomp => true).runcommand

        matches = prematches.split("\n").grep(/^#{Iptables.target}.+#{ip}/).size
        matches >= 1
      end

      # Returns the target to use for rules
      def self.target
        config = Config.instance
        target = "DROP"

        if config.pluginconf.include?("iptables.target")
          target = config.pluginconf["iptables.target"]
        end

        target
      end

      private
      # Deals with requests to block an ip
      def blockip(ip)
        logger.debug("Blocking #{ip} with target #{Iptables.target}")

        out = ""

        # if he's already blocked we just dont bother doing it again
        unless Iptables.isblocked?(ip)
          Shell.new("/sbin/iptables -A junk_filter -s #{ip} -j #{Iptables.target} 2>&1", :stdout => out, :chomp => true).runcommand
          Shell.new("/usr/bin/logger -i -t mcollective 'Attempted to add #{ip} to iptables junk_filter chain on #{Socket.gethostname}'").runcommand
        else
          reply.fail! "#{ip} was already blocked"
          return
        end

        if Iptables.isblocked?(ip)
          unless out == ""
            reply[:output] = out
          else
            reply[:output] = "#{ip} was blocked"
          end
        else
          reply.fail! "Failed to add #{ip}: #{out}"
        end
      end

      # Deals with requests to unblock an ip
      def unblockip(ip)
        logger.debug("Unblocking #{ip} with target #{Iptables.target}")

        out = ""

        # remove it if it's blocked
        if Iptables.isblocked?(ip)
          Shell.new("/sbin/iptables -D junk_filter -s #{ip} -j #{Iptables.target} 2>&1", :stdout => out, :chomp => true).runcommand
          Shell.new("/usr/bin/logger -i -t mcollective 'Attempted to remove #{ip} from iptables junk_filter chain on #{Socket.gethostname}'").runcommand
        else
          reply.fail! "#{ip} was already unblocked"
          return
        end

        # check it was removed
        if Iptables.isblocked?(ip)
          reply.fail! "IP left blocked, iptables says: #{out}"
        else
          unless out == ""
            reply[:output] = out
          else
            reply[:output] = "#{ip} was unblocked"
          end
        end
      end

      # Returns a list of blocked ips
      def listblocked
        preout = ""
        Shell.new("/sbin/iptables -L junk_filter -n 2>&1", :stdout => preout, :chomp => true).runcommand

        out = preout.split("\n").grep(/^#{Iptables.target}/)
        out.map {|l| l.split(/\s+/)[3]}
      end
    end
  end
end

# vi:tabstop=2:expandtab:ai:filetype=ruby
