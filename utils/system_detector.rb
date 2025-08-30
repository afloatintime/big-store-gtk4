class SystemDetector
  def initialize
    @os_release = {}
    
    # Read /etc/os-release if it exists
    if File.exist?('/etc/os-release')
      File.readlines('/etc/os-release').each do |line|
        key, value = line.strip.split('=', 2)
        @os_release[key] = value.gsub(/^"|"$/, '') if key && value
      end
    end
  end

  def is_biglinux?
    @os_release['ID'] == 'biglinux' || @os_release['ID'] == 'bigcommunity'
  end

  def has_pacman?
    # Check if pacman is available
    system('which pacman > /dev/null 2>&1')
  end

  def has_flatpak?
    # Check if Flatpak is available
    system('which flatpak > /dev/null 2>&1')
  end

  def has_pactrans?
    # Check if pactrans (from pactrans-overwrite) is available
    system('which pactrans > /dev/null 2>&1')
  end

  def has_aur?
    # Check if AUR helpers are available (Arch-based systems)
    system('which pacman > /dev/null 2>&1') && 
    (system('which yay > /dev/null 2>&1') || system('which pamac > /dev/null 2>&1'))
  end
end
