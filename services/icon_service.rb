class IconService
  def initialize(config = Config.new)
    @config = config
  end

  def get_app_icon(app_id, app_type, icon_path = nil)
    if app_type == :flatpak
      # For Flatpak apps, download from Flathub
      return nil unless icon_path
      
      local_path = File.join(@config.cache_dir, "icons", "#{app_id}.png")
      
      unless File.exist?(local_path)
        require 'fileutils'
        FileUtils.mkdir_p(File.dirname(local_path))
        
        begin
          URI.open(icon_path) do |image|
            File.open(local_path, 'wb') { |f| f.write(image.read) }
          end
        rescue => e
          puts "Error downloading icon: #{e.message}"
          return nil
        end
      end
      
      local_path
    else
      # For native apps, use system theme icon
      get_theme_icon(app_id)
    end
  end

  def get_theme_icon(app_id)
    # Try to find the icon in the system theme
    icon_paths = [
      "/usr/share/icons/hicolor/512x512/apps/#{app_id}.png",
      "/usr/share/icons/hicolor/256x256/apps/#{app_id}.png",
      "/usr/share/icons/hicolor/128x128/apps/#{app_id}.png",
      "/usr/share/icons/hicolor/64x64/apps/#{app_id}.png",
      "/usr/share/icons/hicolor/48x48/apps/#{app_id}.png",
      "/usr/share/icons/hicolor/32x32/apps/#{app_id}.png",
      "/usr/share/pixmaps/#{app_id}.png"
    ]
    
    icon_paths.each do |path|
      return path if File.exist?(path)
    end
    
    # Return a default icon if none found
    default_icon = File.join(__dir__, '..', '..', 'assets', 'icons', 'default-app-icon.png')
    File.exist?(default_icon) ? default_icon : nil
  end
end
