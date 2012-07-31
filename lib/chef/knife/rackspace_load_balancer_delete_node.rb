require 'chef/knife'
require 'chef/knife/rackspace_base'
require 'chef/knife/rackspace_load_balancer_base'
require 'chef/knife/rackspace_load_balancer_nodes'
require 'cloudlb'

module KnifePlugins
  class RackspaceLoadBalancerDeleteNode < Chef::Knife
    include Chef::Knife::RackspaceBase
    include Chef::Knife::RackspaceLoadBalancerBase
    include Chef::Knife::RackspaceLoadBalancerNodes

    banner "knife rackspace load balancer delete node (options)"

    option :force,
      :long => "--force",
      :description => "Skip user input"

    option :all,
      :long => "--all",
      :description => "Remove from all load balancers"

    option :except,
      :long => "--except \"ID[,ID]\"",
      :description => "List of load balancer ids to omit (Implies --all)"

    option :only,
      :long => "--only \"ID[,ID]\"",
      :description => "List of load balancer ids to remove from"

    option :by_name,
      :long => "--by-name \"NAME[,NAME]\"",
      :description => "Resolve names against chef server to produce list of nodes to remove"

    option :by_private_ip,
      :long => "--by-private-ip \"IP[,IP]\"",
      :description => "List of nodes given by private ips to remove"

    option :by_search,
      :long => "--by-search SEARCH",
      :description => "Resolve search against chef server to produce list of nodes to remove"

    def run
      unless [:all, :except, :only].any? {|target| not config[target].nil?}
        ui.fatal("Must provide a target set of load balancers with --all, --except, or --only")
        show_usage
        exit 1
      end

      unless [:by_name, :by_private_ip, :by_search].any? {|addition| not config[addition].nil?}
        ui.fatal("Must provide a set of nodes to remove with --by-name, --by-private-ip, or --by-search")
        show_usage
        exit 2
      end

      node_ips = resolve_node_ips_from_config({
        :by_search     => config[:by_search],
        :by_name       => config[:by_name],
        :by_private_ip => config[:by_private_ip]
      })

      nodes = node_ips.map do |ip|
        { :address => ip }
      end

      if nodes.empty?
        ui.fatal("Node resolution did not provide a set of nodes for removal")
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
        ui.confirm("Do you really want to remove these nodes")
      end

      target_load_balancers.each do |lb|
        begin
          ui.output("Opening #{lb[:name]}")
          balancer = lb_connection.get_load_balancer(lb[:id])

          lb_nodes = balancer.list_nodes

          nodes_to_remove = []
          already_removed = []
          nodes.each do |node|
            if (lb_node = lb_nodes.find{|lb_node| lb_node[:address] == node[:address]})
              nodes_to_remove << lb_node
            else
              already_removed << node
            end
          end
          if !already_removed.empty?
            removed_names = already_removed.map { |node| node[:address] }
            ui.warn "Already out of load balancer - skipping: #{removed_names.join(', ')}"
          end

          unless nodes_to_remove.empty?
            ui.output("Removing #{nodes_to_remove.size} node(s) from #{lb[:name]}")
            balancer.destroy_nodes(nodes_to_remove)
          end
        rescue CloudLB::Exception::Other => e
          ui.error("Failed on #{lb[:name]}: CloudLB::Exception [#{e.class.name}] - #{e.message}")
        end
      end

      ui.output(ui.color("Complete", :green))
    end
  end
end

