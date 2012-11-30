metadata :name => "Iptables",
         :description => "Checks if an IPv4 address is blocked",
         :author => "Pieter Loubser <pieter.loubser@puppetlabs.com>",
         :license => "ASL 2.0",
         :version => "1.0",
         :url => "http://marionette-collective.org/",
         :timeout => 1

dataquery :description => "Iptables" do
    input :query,
          :prompt => "IPv4 Address",
          :description => "Valid IPv4 address",
          :type => :string,
          :validation => :ipv4address,
          :maxlength => 50

    output :blocked,
           :description => "True/False value of blocked status",
           :display_as => "Blocked"
end
