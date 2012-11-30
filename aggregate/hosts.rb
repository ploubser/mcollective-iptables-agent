module MCollective
  class Aggregate
    class Hosts<Base
      # This aggregate function will print a list of all input results
      # specified in the ddl and a matching array of hosts which share
      # the same value.
      #
      # Example
      #    foo : [a.com, c.com]
      #    bar : [b.com, d.com]
      def startup_hook
        @result[:value] = {}
        @result[:type] = :collection

        @aggregate_format = "%s : [%s]" unless @aggregate_format
      end

      def process_result(value, reply)
        @result[:value][value] ||= []
        @result[:value][value] << reply.results[:sender]
      end

      def summarize
        @result[:value].each do |k,v|
          @result[:value][k] = v.join(',')
        end

        super
      end
    end
  end
end
