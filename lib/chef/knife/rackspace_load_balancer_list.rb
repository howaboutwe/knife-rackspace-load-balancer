require 'chef/knife'
require 'chef/knife/rackspace_base'
require 'chef/knife/rackspace_load_balancer_base'
require 'cloudlb'

module KnifePlugins
  class RackspaceLoadBalancerList < Chef::Knife

    include Chef::Knife::RackspaceBase
    include Chef::Knife::RackspaceLoadBalancerBase

    banner "knife rackspace load balancer list"

    def run
      load_balancer_list = [
        ui.color("Id", :bold),
        ui.color("Name", :bold),
        ui.color("Nodes", :bold),
        ui.color("Virtual Ip", :bold),
        ui.color("Protocol / Port", :bold),
        ui.color("Status", :bold),
      ]

      lb_connection.list_load_balancers.each do |load_balancer|
        vip = (load_balancer[:virtualIps].detect {|vip| vip[:ipVersion] == "IPV4"})
        vip ||= load_balancer[:virtualIps].first

        load_balancer_list << load_balancer[:id].to_s
        load_balancer_list << load_balancer[:name].to_s
        load_balancer_list << load_balancer[:nodeCount].to_s
        load_balancer_list << (vip.nil? ? "None" : vip[:address].to_s)
        load_balancer_list << "#{load_balancer[:protocol]} / #{load_balancer[:port].to_s}"
        load_balancer_list << ui.color(load_balancer[:status].to_s, load_balancer[:status] == "ACTIVE" ? :green : :red)
      end

      puts ui.list(load_balancer_list, :columns_across, 6)
    end
  end
end
