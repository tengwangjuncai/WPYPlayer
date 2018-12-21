# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

target 'WPYPlayer' do
    # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
    use_frameworks!
    
    # Pods for ImGuider X
    #    网络请求
    pod 'Moya'
    #    网络图片加载
    pod 'Kingfisher'
    #    自动布局
    pod 'SnapKit'
    
    #    -------------祛除警告------------
    inhibit_all_warnings!
    #   codesigning 错误
    post_install do |installer|
        
        # 需要指定编译版本的第三方的名称 swift 4.0
        myTargets = ['swiftScan']# swiftScan 1.1.5;
        
        installer.pods_project.targets.each do |target|
            if myTargets.include? target.name
                target.build_configurations.each do |config|
                    config.build_settings['SWIFT_VERSION'] = '4.0'
                end
            end
        end
        
        installer.pods_project.build_configurations.each do |config|
            config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = [
            '$(FRAMEWORK_SEARCH_PATHS)'
            ]
            installer.pods_project.build_configurations.each do |config|
                config.build_settings.delete('CODE_SIGNING_ALLOWED')
                config.build_settings.delete('CODE_SIGNING_REQUIRED')
            end
        end
    end
    
end
