module Cartography
  class Engine < ::Rails::Engine
    initializer 'cartography.assets.precompile' do |app|
      app.config.assets.precompile += %w[cartography.css cartography.js]
    end

    initializer :i18n do |app|
      app.config.i18n.load_path += Dir[Cartography::Engine.root.join('config', 'locales', '*.yml')]
    end
  end
end
