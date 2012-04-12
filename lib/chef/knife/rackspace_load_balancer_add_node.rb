require 'chef/knife'
require 'chef/knife/rackspace_base'
require 'chef/knife/rackspace_load_balancer_base'
require 'chef/knife/rackspace_load_balancer_nodes'
require 'cloudlb'

module KnifePlugins
  class RackspaceLoadBalancerAddNode < Chef::Knife
    include Chef::Knife::RackspaceBase
    include Chef::Knife::RackspaceLoadBalancerBase
    include Chef::Knife::RackspaceLoadBalancerNodes

    banner "knife rackspace load balancer add node (options)"

    option :force,
      :long => "--force",
      :description => "Skip user input"

    option :all,
      :long => "--all",
      :description => "Add to all load balancers"

    option :except,
      :long => "--except \"ID[,ID]\"",
      :description => "Comma deliminated list of load balancer ids to omit (Implies --all)"

    option :only,
      :long => "--only \"ID[,ID]\"",
      :description => "Comma deliminated list of load balancer ids to add to"

    option :port,
      :long => "--port PORT",
      :description => "Add node listening to this port [DEFAULT: 80]",
      :default => "80"

    option :condition,
      :long => "--condition CONDITION",
      :description => "Add node in this condition [DEFAULT: ENABLED]",
      :default => "ENABLED"

    option :weight,
      :long => "--weight WEIGHT",
      :description => "Add node with this weight [DEFAULT: 1]",
      :default => "1"

    option :by_name,
      :long => "--by-name \"NAME[,NAME]\"",
      :description => "Resolve names against chef server to produce list of nodes to add"

    option :by_private_ip,
      :long => "--by-private-ip \"IP[,IP]\"",
      :description => "List of nodes given by private ips to add"

    option :by_search,
      :long => "--by-search SEARCH",
      :description => "Resolve search against chef server to produce list of nodes to add"

    option :auto_resolve_port,
      :long => "--auto-resolve-port",
      :description => "Auto resolve port of node addition"

    def run
      unless [:all, :except, :only].any? {|target| not config[target].nil?}
        ui.fatal("Must provide a target set of load balancers with --all, --except, or --only")
        show_usage
        exit 1
      end

      unless [:by_name, :by_private_ip, :by_search].any? {|addition| not config[addition].nil?}
        ui.fatal("Must provide a set of additional nodes with --by-name, --by-private-ip, or --by-search")
        show_usage
        exit 2
      end

      node_ips = resolve_node_ips_from_config({
        :by_search     => config[:by_search],
        :by_name       => config[:by_name],
        :by_private_ip => config[:by_private_ip]
      })

      nodes = node_ips.map do |ip|
        {
          :address => ip,
          :port => config[:auto_resolve_port] ? "Auto resolve" : config[:port],
          :condition => config[:condition],
          :weight => config[:weight]
        }
      end

      if nodes.empty?
        ui.fatal("Node resolution did not provide a set of nodes for addition")
        exit 3
      end

      target_load_balancers = lb_connection.list_load_balancers

      if config[:only]
        only = config[:only].split(",").map(&:to_s)
        target_load_balancers = target_load_balancers.select {|lb| only.include? lb[:id].to_s}
      end

      if config[:except]
        except = config[:except].split(",").map(&:to_s)
        target_load_balancers = target_load_balancers.reject {|lb| except.include? lb[:id].to_s}
      end

      if target_load_balancers.empty?
        ui.fatal("Load balancer resolution did not provide a set of target load balancers")
        exit 4
      end

      ui.output(format_for_display({
        :targets => target_load_balancers.map {|lb| lb[:name]},
        :nodes => nodes
      }))

      unless config[:force]
        ui.confirm("Do you really want to add these nodes")
      end

      target_load_balancers.each do |lb|
        begin
          ui.output("Opening #{lb[:name]}")
          balancer = lb_connection.get_load_balancer(lb[:id])
          lb_nodes = balancer.list_nodes
          lb_node_ips = lb_nodes.map {|lbn| lbn[:address]}

          if config[:auto_resolve_port]
            nodes_for_balancer = nodes.dup

            port = lb_nodes.first[:port]
            ui.output(ui.color("Auto resolved port to: #{port}", :cyan))

            nodes_for_balancer.each do |nfb|
              nfb[:port] = port
            end
          else
            nodes_for_balancer = nodes
          end

          nodes_for_balancer.each do |node|
            if lb_node_ips.include?(node[:address])
              ui.warn("Skipping node #{node[:address]}")
            else
              ui.output("Adding node #{node[:address]}")
              if balancer.create_node(node)
                ui.output(ui.color("Success", :green))
              else
                ui.output(ui.color("Failed", :red))
              end
            end
          end
        rescue CloudLB::Exception::Other => e
          ui.error("Failed on #{lb[:name]}: CloudLB::Exception [#{e.class.name}] - #{e.message}")
        end
      end

      ui.output(ui.color("Complete", :green))
    end
  end
end
