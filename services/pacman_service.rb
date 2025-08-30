require 'json'

class PacmanService
  def initialize
    # Check if pacman is available
    raise "pacman is not available" unless system('which pacman > /dev/null 2>&1')
  end

  def get_apps(category = nil)
    # Get available apps using pacman
    begin
      # Get all packages from pacman database
      output = `pacman -Ss 2>/dev/null || echo ""`
      apps = []
      
      output.each_line do |line|
        next if line.strip.empty?
        
        # Parse pacman output: "repository/name version description"
        parts = line.strip.split(' ', 3)
        next if parts.length < 3
        
        repo_name, package_info = parts[0].split('/')
        package_name = package_info.to_s
        version = parts[1].to_s
        description = parts[2].to_s
        
        # Skip development packages, libraries, and debug packages
        next if package_name.to_s.include?('-dev') || 
                package_name.to_s.include?('-devel') || 
                package_name.to_s.include?('lib') || 
                package_name.to_s.include?('debug') ||
                package_name.to_s.include?('headers') ||
                package_name.to_s.include?('doc')
        
        # Get package details
        details = get_package_details(package_name)
        
        apps << {
          id: package_name,
          name: get_package_name(package_name),
          version: version,
          description: description,
          categories: details[:categories] || [],
          repository: repo_name,
          type: :native,
          installed: installed?(package_name)
        }
      end
      
      apps
    rescue => e
      puts "Error getting apps from pacman: #{e.message}"
      []
    end
  end

  def get_installed_apps
    # Get installed apps using pacman
    begin
      output = `pacman -Q 2>/dev/null || echo ""`
      apps = []
      
      output.each_line do |line|
        next if line.strip.empty?
        
        parts = line.strip.split(' ')
        next if parts.length < 2
        
        package_name = parts[0].to_s
        version = parts[1].to_s
        
        # Skip development packages, libraries, and debug packages
        next if package_name.to_s.include?('-dev') || 
                package_name.to_s.include?('-devel') || 
                package_name.to_s.include?('lib') || 
                package_name.to_s.include?('debug') ||
                package_name.to_s.include?('headers') ||
                package_name.to_s.include?('doc')
        
        # Get package details
        details = get_package_details(package_name)
        
        apps << {
          id: package_name,
          name: get_package_name(package_name),
          version: version,
          description: details[:description] || "Native package: #{package_name}",
          categories: details[:categories] || [],
          type: :native,
          installed: true
        }
      end
      
      apps
    rescue => e
      puts "Error getting installed apps from pacman: #{e.message}"
      []
    end
  end

  def search_apps(query)
    # Search for apps using pacman
    begin
      output = `pacman -Ss "#{query}" 2>/dev/null || echo ""`
      apps = []
      
      output.each_line do |line|
        next if line.strip.empty?
        
        # Parse pacman output: "repository/name version description"
        parts = line.strip.split(' ', 3)
        next if parts.length < 3
        
        repo_name, package_info = parts[0].split('/')
        package_name = package_info.to_s
        version = parts[1].to_s
        description = parts[2].to_s
        
        # Skip development packages, libraries, and debug packages
        next if package_name.to_s.include?('-dev') || 
                package_name.to_s.include?('-devel') || 
                package_name.to_s.include?('lib') || 
                package_name.to_s.include?('debug') ||
                package_name.to_s.include?('headers') ||
                package_name.to_s.include?('doc')
        
        # Get package details
        details = get_package_details(package_name)
        
        apps << {
          id: package_name,
          name: get_package_name(package_name),
          version: version,
          description: description,
          categories: details[:categories] || [],
          repository: repo_name,
          type: :native,
          installed: installed?(package_name)
        }
      end
      
      apps
    rescue => e
      puts "Error searching apps with pacman: #{e.message}"
      []
    end
  end

  def install_app(app_id)
    # Install an app using pacman
    system("pacman -S --noconfirm #{app_id}")
  end

  def uninstall_app(app_id)
    # Uninstall an app using pacman
    system("pacman -R --noconfirm #{app_id}")
  end

  private

  def get_package_details(package_name)
    # Get package details using pacman
    begin
      output = `pacman -Qi #{package_name} 2>/dev/null || echo ""`
      details = { description: "", categories: [] }
      
      current_field = nil
      output.each_line do |line|
        line = line.strip
        next if line.empty?
        
        if line.include?(':')
          current_field = line.split(':')[0].downcase
          value = line.split(':', 2)[1].to_s.strip
          
          case current_field
          when 'description'
            details[:description] = value
          when 'groups'
            details[:categories] = value.split(',').map(&:strip)
          end
        end
      end
      
      details
    rescue => e
      puts "Error getting package details: #{e.message}"
      { description: "", categories: [] }
    end
  end

  def get_package_name(package_name)
    # Convert package name to user-friendly format
    package_name.to_s.split('-').map(&:capitalize).join(' ')
  end

  def installed?(package_id)
    # Check if a package is installed using a more robust method
    return false if package_id.nil? || package_id.empty?
    
    begin
      # Get list of installed packages and check if package_id is in the list
      output = `pacman -Q 2>/dev/null || echo ""`
      installed_packages = output.split("\n").map { |line| line.split(' ', 2)[0].to_s }
      installed_packages.include?(package_id.strip)
    rescue => e
      puts "Error checking if package is installed: #{e.message}"
      false
    end
  end
end
