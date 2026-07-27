require 'json'

package = JSON.parse(File.read(File.join(__dir__, '..', 'package.json')))

Pod::Spec.new do |s|
  s.name           = 'ExpoRoomplan'
  s.version        = package['version']
  s.summary        = package['description']
  s.description    = package['description']
  s.license        = package['license']
  s.author         = package['author']
  s.homepage       = package['homepage']
  s.platforms      = {
    :ios => '16.0'
  }
  s.swift_version  = '5.4'
  s.source         = { git: 'https://github.com/fordat/expo-roomplan' }
  s.static_framework = true

  s.dependency 'ExpoModulesCore'

  # Swift/Objective-C compatibility
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
  }

  s.ios.deployment_target = '16.0'

  # Explicitly link system frameworks used by RoomPlan
  s.frameworks = 'RoomPlan', 'RealityKit', 'ARKit'

  s.source_files = "**/*.{h,m,mm,swift,hpp,cpp}"

end
