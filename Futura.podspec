Pod::Spec.new do |s|

  s.name         = 'Futura'
  s.version      = '2.3.1'
  s.summary      = 'Asynchronous Swift made easy'
  s.description  = 'Futura is a library that provides simple yet powerful tools for working with asynchronous and concurrent code in Swift.'
  s.homepage     = 'https://www.miquido.com/'
  s.license      = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author       = { 'Kacper Kaliński' => 'kacper.kalinski@miquido.com' }
  s.source       = { :git => 'https://github.com/miquido/futura.git', :tag => s.version }
  s.source_files = 'Sources/Futura/**/*.swift'
  
  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.12'
  s.tvos.deployment_target = '10.0'
  
  s.swift_versions = ['5.0', '5.1']

end
