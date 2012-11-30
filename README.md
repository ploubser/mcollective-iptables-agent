#MCollective IP Tables Junkfilter Agent

This agent will add, query and remove iptables rules to a specific iptables chain called junk_filter.

I use a specific table here since I have a list of all my bad IPs that I can just jump to whenever I want to block this traffic.
```
-I INPUT -p tcp --dport 22 -j junk_filter
-I INPUT -p tcp --dport 22 --syn -j ACCEPT
```
Something like this will block all the junk filtered ips but just allow. My IDS use this rule to block people who do SSH brute force scans and so forth against my servers, I get to pick which ports are subject to this filter using the rule patten above.

At present you can only block specific single IP Addresses

##Installation
* Each node need to first have the junk_filter rule on it, the agent wont create an empty one
* Follow the [basic plugin install guide](http://projects.puppetlabs.com/projects/mcollective-plugins/wiki/InstalingPlugins)

Keep in mind:

* You need to thoroughly test this code outside of production, make very certain it does what you expect.
* MCollective will need to run as root for this to work
* Did I mention you need to test it works?

##Configuration
By default the agent will use the DROP target, you can configure it in server.cfg:
```
plugin.iptables.target = REJECT
```

##Usage
You can block an IP:
```
 iptables block 192.168.1.1

 * [ ============================================================> ] 17 / 17


Finished processing 17 / 17 hosts in 523.23 ms
```
Query the IP:
```
% mco iptables -I some.node isblocked 192.168.1.1

 * [ ============================================================> ] 1 / 1

some.node                   192.168.1.1 is blocked

Finished processing 1 / 1 hosts in 536.96 ms
```
Unblock the IP:
```
% mco iptables unblock 192.168.1.1

 * [ ============================================================> ] 17 / 17


Finished processing 17 / 17 hosts in 520.98 ms
```
The agent is a SimpleRPC agent, you can interact with it via the normal RPC methods:
```
% mco rpc iptables isblocked ipaddr=192.168.1.1 -I some.node
Determining the amount of hosts matching filter for 2 seconds .... 17

 * [ ============================================================> ] 1 / 1


some.node
   Result: 192.168.1.1 is not blocked

Finished processing 1 / 1 hosts in 523.30 ms
```

###Iptables Data plugin
The Iptables agent also supplies a data plugin which uses the iptables agent to check if a specified ipv4 address is being blocked. The data plugin will return 'true' or 'false' and can be used during discovery or any other place where the MCollective discovery language is used.
```
mco rpc rpcutil -S "Iptables('1.2.3.4').blocked=true"
```
