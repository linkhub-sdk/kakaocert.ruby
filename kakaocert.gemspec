Gem::Specification.new do |s|
  s.name        = 'kakaocert'
  s.version     = '2.0.0'
  s.date        = '2020-09-09'
  s.summary     = 'Kakaocert API SDK'
  s.description = 'Kakaocert API SDK'
  s.authors     = ["Linkhub Dev"]
  s.email       = 'code@linkhub.co.kr'
  s.files       = [
    "lib/kakaocert.rb"
  ]
  s.license     = 'APACHE LICENSE VERSION 2.0'
  s.homepage    = 'https://github.com/linkhub-sdk/kakaocert.ruby'
  s.required_ruby_version = '>= 2.0.0'
  s.add_runtime_dependency 'linkhub', '1.2.0'
end
