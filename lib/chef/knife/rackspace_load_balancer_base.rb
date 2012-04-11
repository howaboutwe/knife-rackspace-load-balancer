class Chef
  class Knife
    module RackspaceLoadBalancerBase
      def self.included(base)
        base.class_eval do
          option :rackspace_api_region,
            :short => "-R REGION",
            :long => "--rackspace-api-region REGION",
            :description => "Your rackspace API region. IE: ord, dfw",
            :proc => Proc.new {|region| Chef::Config[:knife][:rackspace_api_region] = region}
        end
      end
      def rackspace_api_credentials
        {
          :username => Chef::Config[:knife][:rackspace_api_username],
          :api_key => Chef::Config[:knife][:rackspace_api_key],
          :region => Chef::Config[:knife][:rackspace_api_region]
        }
      end

      def lb_connection
        @lb_connection ||= CloudLB::Connection.new(rackspace_api_credentials)
      end
    end
  end
end
