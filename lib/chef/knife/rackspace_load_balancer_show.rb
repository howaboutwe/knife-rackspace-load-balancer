require 'chef/knife'
require 'chef/search/query'
require 'chef/knife/rackspace_base'
require 'chef/knife/rackspace_load_balancer_base'
require 'cloudlb'

module KnifePlugins
  class RackspaceLoadBalancerShow < Chef::Knife
    include Chef::Knife::RackspaceBase
    include Chef::Knife::RackspaceLoadBalancerBase

    banner "knife rackspace load balancer show LOAD_BALANCER_ID"

    option :resolve_node_names,
      :long => "--resolve-node-names",
      :description => "Resolve node names against chef server"

    def run
      @name_args.each do |load_balancer_id|
        load_balancer = lb_connection.get_load_balancer(load_balancer_id)
        nodes = load_balancer.list_nodes

        load_balancer_info = {
          :name => load_balancer.name,
          :protocol => load_balancer.protocol,
          :port => load_balancer.port,
          :status => ui.color(load_balancer.status, load_balancer.status == "ACTIVE" ? :green : :red)
        }

        vip_list = [
          ui.color("Virtual Ip(s)", :bold),
          ui.color("Version", :bold),
        ]

        load_balancer.list_virtual_ips.each do |vip|
          vip_list << vip[:address]
          vip_list << vip[:ipVersion]
        end

        node_list = [
          ui.color("Node(s)", :bold),
          ui.color("Address", :bold),
          ui.color("Port", :bold),
          ui.color("Status", :bold)
        ]

        nodes.each do |node|
          node_name = node[:id]

          if config[:resolve_node_names]
            Chef::Search::Query.new.search(:node, "private_ip:#{node[:address]}") do |n|
              node_name = n.name unless n.nil? || n.name.nil?
            end
          end

          node_list << node_name.to_s
          node_list << node[:address].to_s
          node_list << node[:port].to_s
          node_list << ui.color(node[:status].to_s, node[:status] == "ONLINE" ? :green : :red)
        end

        ui.output(format_for_display(load_balancer_info))
        ui.output("\n")
        ui.output(ui.list(vip_list, :columns_across, 2))
        ui.output(ui.list(node_list, :columns_across, 4))
      end
    end
  end
end
