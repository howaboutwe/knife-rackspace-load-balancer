require 'chef/knife'
require 'chef/knife/rackspace_base'
require 'chef/knife/rackspace_load_balancer_base'
require 'cloudlb'

require 'chef/knife/rackspace_load_balancer_show'

module KnifePlugins
  class RackspaceLoadBalancerDelete < Chef::Knife
    include Chef::Knife::RackspaceBase
    include Chef::Knife::RackspaceLoadBalancerBase

    banner "knife rackspace load balancer delete ID [ID] (options)"

    option :force,
      :long => "--force",
      :description => "Skip user prompts"

    option :resolve_node_names,
      :long => "--resolve-node-names",
      :description => "Resolve node names against Chef Server"

    def run
      @name_args.each do |load_balancer_id|
        show_load_balancer = RackspaceLoadBalancerShow.new
        show_load_balancer.config[:resolve_node_names] = true if config[:resolve_node_names]
        show_load_balancer.name_args = [load_balancer_id]
        show_load_balancer.run

        unless config[:force]
          ui.confirm("Do you really want to delete this load balancer")
        end

        load_balancer = lb_connection.get_load_balancer(load_balancer_id)
        load_balancer.destroy!

        ui.warn("Deleted load balancer #{load_balancer_id}")
      end
    end
  end
end
