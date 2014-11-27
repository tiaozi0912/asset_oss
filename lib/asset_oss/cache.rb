require 'yaml'

module AssetOSS
  class Cache
    
    def self.empty
      @cache = {}
    end
    
    # Store the asset fingerprints that need to be removed from OSS
    def self.fingerprints_to_delete
      @fingerprints_to_delete ||= []
    end

    def self.fingerprints_to_delete= fingerprints
      @fingerprints_to_delete = fingerprints
    end
    
    def self.cache
      @cache ||= YAML.load_file(cache_path) rescue {}
    end
    
    def self.cache_path
      File.join(Rails.root, 'log', 'asset_oss_cache.yml')
    end
    
    def self.get(asset)
      cache[asset.relative_path]
    end
    
    def self.hit?(asset)
      if cache[asset.relative_path]
        if cache[asset.relative_path][:fingerprint] != asset.fingerprint
          fingerprints_to_delete << cache[asset.relative_path][:fingerprint]
        else
          return true
        end
      end

      cache[asset.relative_path] = {:expires => asset.expiry_date.to_s, :fingerprint => asset.fingerprint}
      false
    end
  
    def self.miss?(asset)
      !hit?(asset)
    end
    
    def self.save!
      File.open(cache_path, 'w') {|f| f.write(YAML.dump(cache))}
    end
  
  end
end
