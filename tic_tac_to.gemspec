# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tic_tac_toe/version'

Gem::Specification.new do |spec|
  spec.name          = "tictactoe_gem"
  spec.version       = TicTacToe::VERSION
  spec.authors       = ["Adrian Setyadi"]
  spec.email         = ["a.styd@yahoo.com"]

  spec.summary       = %q{Tic Tac Toe on the terminal}
  spec.description   = %q{Try to create a line horizontally, vertically, or diagonally with your symbol. Fun game!}
  spec.homepage      = "https://github.com/styd/TicTacToe"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
