Gem::Specification.new do |s|
  s.name        = 'vacancy_parser'
  s.version     = '0.1.0'
  s.summary     = "Vacancy parser for hh.ru"
  s.description = "Parses vacancies from hh.ru and generates statistics"
  s.authors     = ["Сентюрина Дарья ","Исакова Хадижат"]
  s.email       = ["team@example.com"]
  s.files       = Dir["lib/**/*.rb", "README.md", "LICENSE"]
  s.require_paths = ["lib"]
  s.homepage    = "https://github.com/hadizz-z/vacancy_parser"
  s.license     = "MIT"
  

  s.required_ruby_version = '>= 2.7'
  s.metadata = { 'rubygems_mfa_required' => 'false' }
end
