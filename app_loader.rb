# app_loader.rb

# First, load all models
require_relative 'models/app'
require_relative 'models/category'

# Then load services
require_relative 'services/icon_service'
require_relative 'services/flatpak_service'
require_relative 'services/packagekit_service'
require_relative 'services/pactrans_service'

# Then load views
require_relative 'views/app_view'
require_relative 'views/installed_view'
require_relative 'views/main_view'

# Finally load utils
require_relative 'utils/config'
require_relative 'utils/system_detector'
