$:.push File.expand_path("../lib", __FILE__)
require "version"

Gem::Specification.new do |s|
  s.name = "knife-rackspace-loadbalancer"
  s.version = Knife::Rackspace::LoadBalancer::VERSION
  s.authors = ["Matthew Vermaak"]
  s.summary = "Rackspace Load Balancer Support for Chef's Knife Command"
  s.description = s.summary
  s.files = `git ls-files`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map {|f| File.basename(f)}
  s.add_dependency "chef", "~> 0.10.8"
  s.add_dependency "knife-rackspace", "~> 0.5.12"
  s.add_dependency "cloudlb", "~> 0.1.0"
  s.require_paths = ["lib"]
end
