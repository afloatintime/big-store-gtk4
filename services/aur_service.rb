require 'net/http'
require 'json'

class AurService
  def initialize
    # Check if AUR helpers are available
    @yay_available = system('which yay > /dev/null 2>&1')
    @pamac_available = system('which pamac > /dev/null 2>&1')
    @aur_available = @yay_available || @pamac_available
  end

  def available?
    @aur_available
  end

  def get_apps(category = nil)
    return [] unless @aur_available
    
    # Get AUR apps based on category
    apps = []
    
    # Common AUR apps by category
    aur_apps_by_category = {
      'audio' => ['spotify', 'cider', 'lollypop', 'cmus'],
      'video' => ['vlc', 'mpv', 'obs-studio', 'kodi'],
      'graphics' => ['gimp', 'inkscape', 'krita', 'digikam'],
      'games' => ['steam', 'lutris', 'heroic-games-launcher', 'minecraft-launcher'],
      'office' => ['libreoffice-fresh', 'wps-office', 'onlyoffice-bin'],
      'development' => ['visual-studio-code-bin', 'intellij-idea-ultimate-edition', 'postman-bin', 'github-desktop-bin'],
      'network' => ['discord', 'slack-desktop', 'zoom', 'teams'],
      'utility' => ['alacritty', 'neofetch', 'htop', 'btop']
    }
    
    if category && aur_apps_by_category[category.to_s]
      aur_apps_by_category[category.to_s].each do |app_name|
        # Get package info from AUR API
        package_info = get_aur_package_info(app_name)
        
        if package_info
          apps << {
            id: app_name,
            name: get_package_name(app_name),
            description: package_info['Description'].to_s,
            version: package_info['Version'].to_s,
            type: :aur,
            installed: installed?(app_name)
          }
        end
      end
    end
    
    apps
  end

  def search_apps(query)
    return [] unless @aur_available
    
    # Search AUR packages using API
    begin
      url = "https://aur.archlinux.org/rpc/?v=5&type=search&arg=#{URI.encode_www_form_component(query)}"
      response = Net::HTTP.get(URI(url))
      search_results = JSON.parse(response)
      
      apps = []
      if search_results['type'] == 'search' && search_results['results']
        search_results['results'].each do |result|
          # Skip development packages and libraries
          next if result['Name'].to_s.include?('-dev') || 
                  result['Name'].to_s.include?('-devel') || 
                  result['Name'].to_s.include?('lib') || 
                  result['Name'].to_s.include?('debug') ||
                  result['Name'].to_s.include?('git')
          
          apps << {
            id: result['Name'],
            name: get_package_name(result['Name']),
            description: result['Description'].to_s,
            version: result['Version'].to_s,
            type: :aur,
            installed: installed?(result['Name'])
          }
        end
      end
      
      apps
    rescue => e
      puts "Error searching AUR apps: #{e.message}"
      []
    end
  end

  def get_installed_apps
    return [] unless @aur_available
    
    # Get installed AUR packages
    begin
      output = `pacman -Qm 2>/dev/null || echo ""`
      apps = []
      
      output.each_line do |line|
        parts = line.strip.split(' ')
        if parts.length >= 1
          package_name = parts[0].to_s
          
          # Skip development packages and libraries
          next if package_name.include?('-dev') || 
                  package_name.include?('-devel') || 
                  package_name.include?('lib') || 
                  package_name.include?('debug') ||
                  package_name.include?('git')
          
          # Get package info from AUR API
          package_info = get_aur_package_info(package_name)
          
          apps << {
            id: package_name,
            name: get_package_name(package_name),
            version: parts[1].to_s,
            description: package_info ? package_info['Description'].to_s : "AUR package: #{package_name}",
            type: :aur,
            installed: true
          }
        end
      end
      
      apps
    rescue => e
      puts "Error getting installed AUR apps: #{e.message}"
      []
    end
  end

  def install_app(app_id)
    return false unless @aur_available
    
    # Install AUR package using yay or pamac
    if @yay_available
      system("yay -S --noconfirm #{app_id}")
    elsif @pamac_available
      system("pamac install --no-confirm #{app_id}")
    end
  end

  def uninstall_app(app_id)
    return false unless @aur_available
    
    # Uninstall AUR package using yay or pamac
    if @yay_available
      system("yay -R --noconfirm #{app_id}")
    elsif @pamac_available
      system("pamac remove --no-confirm #{app_id}")
    end
  end

  private

  def get_aur_package_info(package_name)
    # Get package info from AUR API
    begin
      url = "https://aur.archlinux.org/rpc/?v=5&type=info&arg[]=#{URI.encode_www_form_component(package_name)}"
      response = Net::HTTP.get(URI(url))
      result = JSON.parse(response)
      
      if result['type'] == 'info' && result['results'] && !result['results'].empty?
        result['results'][0]
      else
        nil
      end
    rescue => e
      puts "Error getting AUR package info: #{e.message}"
      nil
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
