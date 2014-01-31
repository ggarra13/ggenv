require "rubygems"

spec = Gem::Specification.new do |spec|
	spec.name = "ggenv"
	spec.version = '0.5'
	spec.author = "Gonzalo Garramuno" 
	spec.email = 'GGarramuno@aol.com'
	spec.homepage = 'http://www.rubyforge.org/projects/ggenv/'
	spec.summary = 'Environment variable manipulation using ruby arrays.'
	spec.require_path = "lib"
	spec.autorequire = "GGEnv"
	spec.files = ["lib/GGEnv.rb"]
	spec.description = <<-EOF
	Environment variable manipulation using a ruby array syntax.
EOF
	spec.extra_rdoc_files = ["HISTORY.txt", "GGenv.gemspec"]
	spec.has_rdoc = true
	spec.rubyforge_project = 'ggenv'
	spec.required_ruby_version = '>= 1.6.8'
end
