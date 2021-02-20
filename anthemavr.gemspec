require_relative 'lib/anthem/avr/version'

Gem::Specification.new do |spec|
  spec.name          = "anthemavr"
  spec.version       = Anthem::AVR::VERSION
  spec.authors       = ["Cody Cutrer"]
  spec.email         = ["cody@cutrer.us"]

  spec.summary       = %q{Ruby Library and Homie MQTT Bridge for Anthem AVRs}
  spec.homepage      = "https://github.com/ccutrer/ruby-anthemavr"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.files = Dir["{exe,lib}/**/*"]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'ccutrer-serialport', "~> 1.1"
  spec.add_dependency 'homie-mqtt', "~> 1.2"
  spec.add_dependency 'net-telnet-rfc2217', "~> 1.0"
  spec.add_dependency 'thor', '~> 1.1'

  spec.add_development_dependency 'byebug', "~> 9.0"
  spec.add_development_dependency 'rake', "~> 13.0"
end
