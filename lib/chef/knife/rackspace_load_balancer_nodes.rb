class Chef
  class Knife
    module RackspaceLoadBalancerNodes
      def nodes_by_search(query)
        nodes = []
        Chef::Search::Query.new.search(:node, query) do |n|
          nodes << n
        end

        nodes
      end

      def resolve_node_ips_from_config(options)
        node_ips = []

        if options[:by_search]
          nodes_from_chef = nodes_by_search(options[:by_search])
          node_ips = find_internal_ip_from_node(nodes_from_chef)

        elsif options[:by_name]
          node_names = options[:by_name].split(",")
          nodes_from_chef = nodes_by_search(
            node_names.map {|n| "name:#{n}"}.join(" OR ")
          )

          node_ips = find_internal_ip_from_node(nodes_from_chef)

        elsif options[:by_private_ip]
          node_ips = config[:by_private_ip].split(",")
        end

        node_ips
      end

      private

      def find_internal_ip_from_node(nodes)
        nodes.map do |node|
          node.network["interfaces"]["eth1"]["addresses"].keys.detect do |ip|
            ip =~ /10\./
          end
        end
      end
    end
  end
end
