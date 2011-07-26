Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '1.3.5'

  s.name = "hobelar"
  s.version = "0.0.5"

  s.summary = "reconnoiter rest interface wrapper"
  s.description = "Hobelar talks to reconnoiter's noit rest interface"

  s.authors = ["Thom May"]
  s.email = "thom@clearairturbulence.org"
  s.homepage = "https://github.com/thommay/hobelar"

  s.require_paths = %w[lib]

  ## Specify any RDoc options here. You'll want to add your README and
  ## LICENSE files to the extra_rdoc_files list.
  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = %w[README.rdoc]

  ## List your runtime dependencies here. Runtime dependencies are those
  ## that are needed for an end user to actually USE your code.
  s.add_dependency('builder')
  s.add_dependency('excon', '>=0.6.0')
  s.add_dependency('nokogiri', '>=1.4.4')

  ## List your development dependencies here. Development dependencies are
  ## those that are only needed during development
  s.add_development_dependency('rake')
  s.add_development_dependency('rspec', '1.3.1')

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {spec,tests}/*`.split("\n")
end
