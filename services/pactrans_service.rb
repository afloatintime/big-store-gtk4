class PactransService
  def initialize
    # Check if pactrans-overwrite is available
    raise "pactrans-overwrite is not available" unless system('which pactrans > /dev/null 2>&1')
  end

  def get_apps(category = nil)
    # Get available apps using pactrans-overwrite
    begin
      output = `pactrans list-available 2>/dev/null || echo ""`
      apps = []
      
      output.each_line do |line|
        next if line.strip.empty?
        
        parts = line.strip.split(';')
        next if parts.length < 2
        
        # Skip development packages and libraries
        next if parts[0].to_s.include?('-dev') || 
                parts[0].to_s.include?('-devel') || 
                parts[0].to_s.include?('lib') || 
                parts[0].to_s.include?('debug') ||
                parts[0].to_s.include?('headers') ||
                parts[0].to_s.include?('doc')
        
        apps << {
          id: parts[0],
          name: get_package_name(parts[0]),
          version: parts[2] || '',
          description: "BigLinux package: #{parts[0]}",
          categories: get_package_categories(parts[0]),
          type: :biglinux,
          installed: installed?(parts[0])
        }
      end
      
      apps
    rescue => e
      puts "Error getting apps from pactrans: #{e.message}"
      []
    end
  end

  def get_installed_apps
    # Get installed apps using pactrans-overwrite
    begin
      output = `pactrans list-installed 2>/dev/null || echo ""`
      apps = []
      
      output.each_line do |line|
        next if line.strip.empty?
        
        parts = line.strip.split(';')
        next if parts.length < 2
        
        # Skip development packages and libraries
        next if parts[0].to_s.include?('-dev') || 
                parts[0].to_s.include?('-devel') || 
                parts[0].to_s.include?('lib') || 
                parts[0].to_s.include?('debug') ||
                parts[0].to_s.include?('headers') ||
                parts[0].to_s.include?('doc')
        
        apps << {
          id: parts[0],
          name: get_package_name(parts[0]),
          version: parts[2] || '',
          description: "BigLinux package: #{parts[0]}",
          categories: get_package_categories(parts[0]),
          type: :biglinux,
          installed: true
        }
      end
      
      apps
    rescue => e
      puts "Error getting installed apps from pactrans: #{e.message}"
      []
    end
  end

  def search_apps(query)
    # Search for apps using pactrans-overwrite
    begin
      output = `pactrans search "#{query}" 2>/dev/null || echo ""`
      apps = []
      
      output.each_line do |line|
        next if line.strip.empty?
        
        parts = line.strip.split(';')
        next if parts.length < 2
        
        # Skip development packages and libraries
        next if parts[0].to_s.include?('-dev') || 
                parts[0].to_s.include?('-devel') || 
                parts[0].to_s.include?('lib') || 
                parts[0].to_s.include?('debug') ||
                parts[0].to_s.include?('headers') ||
                parts[0].to_s.include?('doc')
        
        apps << {
          id: parts[0],
          name: get_package_name(parts[0]),
          version: parts[2] || '',
          description: "BigLinux package: #{parts[0]}",
          categories: get_package_categories(parts[0]),
          type: :biglinux,
          installed: installed?(parts[0])
        }
      end
      
      apps
    rescue => e
      puts "Error searching apps with pactrans: #{e.message}"
      []
    end
  end

  def install_app(app_id)
    # Install an app using pactrans-overwrite
    system("pactrans install #{app_id}")
  end

  def uninstall_app(app_id)
    # Uninstall an app using pactrans-overwrite
    system("pactrans remove #{app_id}")
  end

  private

  def get_package_name(package_name)
    # Convert package name to user-friendly format
    package_name.to_s.split('-').map(&:capitalize).join(' ')
  end

  def get_package_categories(package_id)
    # Simple category mapping based on package name
    categories = []
    
    if package_id.to_s.include?('audio') || package_id.to_s.include?('music') || package_id.to_s.include?('sound')
      categories << 'audio'
    elsif package_id.to_s.include?('video') || package_id.to_s.include?('movie') || package_id.to_s.include?('player')
      categories << 'video'
    elsif package_id.to_s.include?('image') || package_id.to_s.include?('photo') || package_id.to_s.include?('graphics')
      categories << 'graphics'
    elsif package_id.to_s.include?('game') || package_id.to_s.include?('steam')
      categories << 'games'
    elsif package_id.to_s.include?('office') || package_id.to_s.include?('document') || package_id.to_s.include?('libreoffice')
      categories << 'office'
    elsif package_id.to_s.include?('network') || package_id.to_s.include?('web') || package_id.to_s.include?('browser')
      categories << 'network'
    elsif package_id.to_s.include?('development') || package_id.to_s.include?('code') || package_id.to_s.include?('ide')
      categories << 'development'
    else
      categories << 'utility'
    end
    
    categories
  end

  def installed?(package_id)
    # Check if a package is installed
    return false if package_id.nil? || package_id.empty?
    
    begin
      system("pactrans is-installed #{package_id} > /dev/null 2>&1")
    rescue => e
      puts "Error checking if package is installed: #{e.message}"
      false
    end
  end
end
