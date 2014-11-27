require 'aliyun/oss'

module AssetOSS
  class OSS
  
    def self.oss_config
      @@config ||= YAML.load_file(File.join(Rails.root, "config/asset_oss.yml"))[Rails.env] rescue nil || {}
    end
  
    def self.connect_to_oss
      Aliyun::OSS::Base.establish_connection!(
        :server => oss_config['host'] || Aliyun::OSS::DEFAULT_HOST,
        :access_key_id => oss_config['access_key_id'],
        :secret_access_key => oss_config['secret_access_key']
      )
    end
  
    def self.oss_permissions
      :public_read
    end
  
    def self.oss_bucket
      oss_config['bucket']
    end
    
    def self.oss_folder
      oss_config['folder']
    end
    
    def self.oss_prefix
      oss_config['prefix'] || oss_bucket_url
    end
    
    def self.oss_bucket_url
      "http://#{oss_bucket}.oss.aliyuncs.com#{oss_folder ? "/#{oss_folder}" : '' }"
    end
    
    def self.full_path(asset)
      oss_folder ? "/#{oss_folder}#{asset.fingerprint}" : asset.fingerprint
    end
    
    # Main method. Usually invoked from a rake task
    # Create or update object in OSS
    # @todo: find the assets deleted locally and delete them in OSS
    def self.upload(options={})
      Asset.init(:debug => options[:debug], :nofingerprint => options[:nofingerprint])
      
      assets = Asset.find
      return if assets.empty?
    
      connect_to_oss

      Aliyun::OSS::Bucket.create(oss_bucket, :access => oss_permissions)
    
      assets.each do |asset|
      
        puts "AssetOSS: #{asset.relative_path}" if options[:debug]
      
        headers = {
          :content_type => asset.mime_type,
        }.merge(asset.cache_headers)
        
        asset.replace_css_images!(:prefix => oss_prefix) if asset.css?
        
        if asset.gzip_type?
          headers.merge!(asset.gzip_headers)
          asset.gzip!
        end
        
        if options[:debug]
          puts "  - Uploading: #{full_path(asset)} [#{asset.data.size} bytes]"
          puts "  - Headers: #{headers.inspect}"
        end

        clean
        
        unless options[:dry_run]
          res = Aliyun::OSS::OSSObject.store(
            full_path(asset),
            asset.data,
            oss_bucket,
            headers
          ) 
          puts "  - Response: #{res.inspect}" if options[:debug]
        end
      end
    
      Cache.save! unless options[:dry_run]
    end

    def self.clean(options={})
      fingerprints = Cache.fingerprints_to_delete
      return if fingerprints.empty?

      fingerprints.each do |f|
        Aliyun::OSS::OSSObject.delete f, oss_bucket
        puts "AssetOSS: delete #{f}" if options[:debug]
      end

      Cache.fingerprints_to_delete= []
    end
  
  end
end
