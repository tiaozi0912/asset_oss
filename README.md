Asset OSS -  上传Rails项目静态文件到Aliyun OSS
===

关于
---

基于[asset_id](https://github.com/moocode/asset_id),[aset_sync](https://github.com/rumblelabs/asset_sync)也许是更好的选择

一个简单的上传Rails assets目录里静态文件到Aliyun OSS工具  

使用和配置
---

添加`gem "asset_oss"`到你的Gemfile

修改`config/environments/production.rb`文件, `config.action_controller.asset_host = "http://my_live_bucket.oss.aliyuncs.com"`

新建一个`config/asset_oss.yml`文件
```
production:
  host: 'oss.aliyuncs.com'
  access_key_id: 'MY_ACCESS_KEY'
  secret_access_key: 'MY_ACCESS_SECRET'
  bucket: "my_live_bucket"
```

创建rake任务, `lib/tasks/asset_oss.rake`
```
namespace :asset do
  namespace :oss do
    
    desc "uploads the current assets to aliyun oss with stamped ids"
    task :upload do
      AssetOSS::Asset.asset_paths += ['assets'] # Configure additional asset paths
      AssetOSS::OSS.upload
    end
    
  end
end
```

其它
---
也许可以通过修改Rails `config.assets.prefix`实现缓存过期,记得prefix要是assets开头,同时修改`AssetOSS::Asset.asset_paths`
