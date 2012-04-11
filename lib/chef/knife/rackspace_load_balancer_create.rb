require 'chef/knife'
require 'chef/knife/rackspace_base'
require 'chef/knife/rackspace_load_balancer_base'
require 'chef/knife/rackspace_load_balancer_nodes'
require 'cloudlb'

module KnifePlugins
  class RackspaceLoadBalancerCreate < Chef::Knife
    include Chef::Knife::RackspaceBase
    include Chef::Knife::RackspaceLoadBalancerBase
    include Chef::Knife::RackspaceLoadBalancerNodes

    banner "knife rackspace load balancer create NAME (options)"

    option :force,
      :long => "--force",
      :description => "Skip user input"

    option :protocol,
      :long => "--protocol PROTOCOL",
      :description => "The protocol to balance [Default: HTTP]",
      :default => "HTTP"

    option :add_nodes_by_search,
      :long => "--add-nodes-by-search SEARCH",
      :description => "Node search query resolved by Chef Server to add"

    option :add_nodes_by_private_ip,
      :long => "--add-nodes-by-private-ip \"IP[,IP]\"",
      :description => "Comma deliminated list of private ips to add"

    option :add_nodes_by_name,
      :long => "--add-nodes-by-name \"NAME[,NAME]\"",
      :description => "Comma deliminated list of node names resolved by Chef Server to add"

    option :node_port,
      :long => "--node-port PORT",
      :description => "Add nodes listening to this port DEFAULT: 80",
      :default => "80"

    option :node_weight,
      :long => "--node-weight WEIGHT",
      :description => "Add nodes with this weight",
      :default => "1"

    option :node_condition,
      :long => "--node-condition CONDITION",
      :description => "Add nodes with this condition",
      :default => "ENABLED"

    option :port,
      :long => "--port PORT",
      :description => "Configure the load balancer to listen to this port DEFAULT: 80",
      :default => "80"

    option :algorithm,
      :long => "--algorithm ALGORITHM",
      :description => "The algorithm to employ for load balancing [Defualt: RANDOM]",
      :default => "RANDOM"

    option :virtual_ip_ids,
      :long => "--virtual-ip-id \"ID[,ID]\"",
      :description => "Comma deliminated list of virtual ip ids"

    option :virtual_ip_type,
      :long => "--virtual-ip-type TYPE",
      :description => "Type of virtual IP to obtain [DEFAULT: PUBLIC]",
      :default => "PUBLIC"



    def run
      if @name_args.first.nil?
        ui.fatal("Must provide name")
        show_usage
        exit 1
      end

      unless [:add_nodes_by_search, :add_nodes_by_name, :add_nodes_by_private_ip].any? {|addition| not config[addition].nil?}
        ui.fatal("Must provide nodes via --add-nodes-by-search, --add-nodes-by-node-name, or --add-nodes-by-private-ip")
        show_usage
        exit 2
      end

      node_ips = resolve_node_ips_from_config({
        :by_search     => config[:add_nodes_by_search],
        :by_name       => config[:add_nodes_by_name],
        :by_private_ip => config[:add_nodes_by_private_ip]
      })

      nodes = node_ips.map do |ip|
        {
          :address => ip,
          :port => config[:node_port],
          :condition => config[:node_condition],
          :weight => config[:node_weight]
        }
      end

      load_balancer_configuration = {
        :name => @name_args.first,
        :protocol => config[:protocol],
        :port => config[:port],
        :algorithm => config[:algorithm],
        :nodes => nodes,
        :virtual_ip_type => config[:virtual_ip_type]
      }

      unless config[:virtual_ip_ids].nil?
        load_balancer_configuration[:virtual_ip_ids] = config[:virtual_ip_ids].split(",")
      end

      ui.output format_for_display(load_balancer_configuration)

      unless config[:force]
        ui.confirm("Do you really want to create this load balancer")
      end

      load_balancer_id = lb_connection.create_load_balancer(load_balancer_configuration)

      ui.output(ui.color("Created load balancer #{@name_args.first}", :green))
    end
  end
end
