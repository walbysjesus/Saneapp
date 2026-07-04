Pod::Spec.new do |s|
  s.name             = 'facebook_auth_desktop'
  s.version          = '0.0.1'
  s.summary          = 'Local stub plugin for dependency resolution.'
  s.description      = <<-DESC
Local stub plugin for non-macOS builds and tests.
                       DESC
  s.homepage         = 'https://local.stub'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Local' => 'local@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.14'
  s.swift_version = '5.0'
end