class Config
  attr_reader :flathub_url, :cache_dir, :app_name, :version

  def initialize
    @flathub_url = "https://flathub.org/api/v1"
    @cache_dir = File.join(Dir.home, '.cache', 'app-store')
    @app_name = "App Store"
    @version = "1.0.0"
    
    # Create cache directory if it doesn't exist
    require 'fileutils'
    FileUtils.mkdir_p(@cache_dir) unless Dir.exist?(@cache_dir)
  end
end
