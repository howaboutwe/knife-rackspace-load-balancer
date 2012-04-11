$:.push File.expand_path("../lib", __FILE__)
require "version"

Gem::Specification.new do |s|
  s.name = "knife-rackspace-load-balancer"
  s.version = Knife::Rackspace::LoadBalancer::VERSION
  s.authors = ["Matthew Vermaak"]
  s.summary = "Rackspace cloud load balancer support for knife"
  s.description = "A gem to extend knife-rackspace allowing cloud load balancer management. Create and destroy load balancers. Add and delete nodes from load balancers."
  s.files = `git ls-files`.split("\n")
  s.add_dependency "chef", "~> 0.10.8"
  s.add_dependency "knife-rackspace", "~> 0.5.12"
  s.add_dependency "cloudlb", "~> 0.1.0"
  s.require_paths = ["lib"]
end
