class Chef
  class Knife
    module RackspaceLoadBalancerBase
      def rackspace_api_credentials
        {
          :username => Chef::Config[:knife][:rackspace_api_username],
          :api_key => Chef::Config[:knife][:rackspace_api_key],
          :region => Chef::Config[:knife][:rackspace_region]
        }
      end

      def lb_connection
        @lb_connection ||= CloudLB::Connection.new(rackspace_api_credentials)
      end
    end
  end
end
