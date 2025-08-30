class PackageKitService
  def initialize
    # Check if PackageKit is available
    raise "PackageKit is not available" unless system('which pkcon > /dev/null 2>&1')
  end

  def get_apps(category = nil)
    # Get available apps using PackageKit
    # This is a simplified implementation
    begin
      # Get all available packages
      output = `pkcon get-packages 2>/dev/null || echo ""`
      apps = []
      
      output.each_line do |line|
        next if line.strip.empty? || line.start_with?('Progress') || line.start_with?('Finished')
        
        parts = line.strip.split(';')
        next if parts.length < 3
        
        # Skip development packages and libraries
        next if parts[1].include?('-dev') || parts[1].include?('-devel') || parts[1].include?('lib')
        
        # Get package details
        details = get_package_details(parts[1])
        
        apps << {
          id: parts[1],
          name: get_package_name(parts[1]),
          version: parts[2],
          description: details[:description] || "System package: #{parts[1]}",
          categories: details[:categories] || [],
          type: :native,
          installed: false
        }
      end
      
      apps
    rescue => e
      puts "Error getting apps from PackageKit: #{e.message}"
      []
    end
  end

  def get_installed_apps
    # Get installed apps using PackageKit
    begin
      output = `pkcon get-packages --installed 2>/dev/null || echo ""`
      apps = []
      
      output.each_line do |line|
        next if line.strip.empty? || line.start_with?('Progress') || line.start_with?('Finished')
        
        parts = line.strip.split(';')
        next if parts.length < 3
        
        # Skip development packages and libraries
        next if parts[1].include?('-dev') || parts[1].include?('-devel') || parts[1].include?('lib')
        
        # Get package details
        details = get_package_details(parts[1])
        
        apps << {
          id: parts[1],
          name: get_package_name(parts[1]),
          version: parts[2],
          description: details[:description] || "System package: #{parts[1]}",
          categories: details[:categories] || [],
          type: :native,
          installed: true
        }
      end
      
      apps
    rescue => e
      puts "Error getting installed apps from PackageKit: #{e.message}"
      []
    end
  end

  def search_apps(query)
    # Search for apps using PackageKit
    begin
      output = `pkcon search "#{query}" 2>/dev/null || echo ""`
      apps = []
      
      output.each_line do |line|
        next if line.strip.empty? || line.start_with?('Progress') || line.start_with?('Finished')
        
        parts = line.strip.split(';')
        next if parts.length < 3
        
        # Skip development packages and libraries
        next if parts[1].include?('-dev') || parts[1].include?('-devel') || parts[1].include?('lib')
        
        # Get package details
        details = get_package_details(parts[1])
        
        apps << {
          id: parts[1],
          name: get_package_name(parts[1]),
          version: parts[2],
          description: details[:description] || "System package: #{parts[1]}",
          categories: details[:categories] || [],
          type: :native,
          installed: installed?(parts[1])
        }
      end
      
      apps
    rescue => e
      puts "Error searching apps with PackageKit: #{e.message}"
      []
    end
  end

  def install_app(app_id)
    # Install an app using PackageKit
    system("pkcon install -y #{app_id}")
  end

  def uninstall_app(app_id)
    # Uninstall an app using PackageKit
    system("pkcon remove -y #{app_id}")
  end

  private

  def get_package_details(package_id)
    # Get package details using PackageKit
    begin
      output = `pkcon get-details #{package_id} 2>/dev/null || echo ""`
      details = { description: "", categories: [] }
      
      output.each_line do |line|
        next if line.strip.empty? || line.start_with?('Progress') || line.start_with?('Finished')
        
        parts = line.strip.split(';')
        if parts.length >= 3
          if parts[0] == 'description'
            details[:description] = parts[2]
          elsif parts[0] == 'category'
            details[:categories] = parts[2].split(',')
          end
        end
      end
      
      details
    rescue => e
      puts "Error getting package details: #{e.message}"
      { description: "", categories: [] }
    end
  end

  def get_package_name(package_id)
    # Convert package name to user-friendly format
    package_id.split('-').map(&:capitalize).join(' ')
  end

  def installed?(package_id)
    # Check if a package is installed
    system("pkcon is-installed #{package_id} > /dev/null 2>&1")
  end
end
