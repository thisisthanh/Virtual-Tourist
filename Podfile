# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Virtual Tourist' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  pod 'Kingfisher', '~> 4.8.0'
  pod 'Alamofire', '~> 4.7.3'
  pod 'SwiftyJSON', '~> 4.1.0'

  # Pods for Virtual Tourist

end

post_install do |installer|
    installer.generated_projects.each do |project|
        project.targets.each do |target|
            target.build_configurations.each do |config|
                config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
            end
        end
    end
end
