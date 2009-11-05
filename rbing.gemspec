# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rbing}
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mike Demers"]
  s.autorequire = %q{rbing}
  s.date = %q{2009-11-05}
  s.default_executable = %q{rbing}
  s.description = %q{A gem that provides an interface to Microsoft's Bing search API}
  s.email = %q{mike@9astronauts.com}
  s.executables = ["rbing"]
  s.extra_rdoc_files = ["README.rdoc", "LICENSE", "TODO"]
  s.files = ["LICENSE", "README.rdoc", "Rakefile", "TODO", "bin/rbing", "lib/rbing.rb", "spec/rbing_spec.rb", "spec/spec_helper.rb"]
  s.homepage = %q{http://9astronauts.com/code/ruby/rbing}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{A gem that provides an interface to Microsoft's Bing search API}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<httparty>, [">= 0.4.0"])
    else
      s.add_dependency(%q<httparty>, [">= 0.4.0"])
    end
  else
    s.add_dependency(%q<httparty>, [">= 0.4.0"])
  end
end
