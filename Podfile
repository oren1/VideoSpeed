# Uncomment the next line to define a global platform for your project
 platform :ios, '17.0'

target 'VideoSpeed' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
    pod 'Google-Mobile-Ads-SDK'
    pod 'FirebaseAnalytics'
    pod 'FirebaseAuth'
    pod 'FirebaseRemoteConfig'
    pod 'Firebase/Messaging'
    pod 'FirebaseCrashlytics'
    pod 'RevenueCat'
    pod 'CropPickerView', '~> 0.3'
    pod 'ActivityIndicatorView'
    pod 'Alamofire'
  # Pods for VideoSpeed

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
