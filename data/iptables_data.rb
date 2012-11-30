module MCollective
  module Data
    class Iptables_data<Base
      activate_when{PluginManager['iptables_agent']}

      query do |ip|
        if Agent::Iptables.isblocked?(ip)
          result[:blocked] = 'true'
        else
          result[:blocked] = 'false'
        end
      end
    end
  end
end
