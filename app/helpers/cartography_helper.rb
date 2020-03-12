module Cartography
  class Configuration

    def initialize(config = {})
      @config = config
      # @categories_colors = @config.delete(:categories_colors)
      # @config[:backgrounds] = MapLayer.available_backgrounds.collect(&:to_json_object)
      # @config[:overlays] = MapLayer.available_overlays.collect(&:to_json_object)
      # @config[:async_url] = @config.delete(:async_url)
    end

    def layer(name, serie, options = {})
      unless options[:label]
        options[:label] = name.is_a?(String) ? name : name.tl(default: "attributes.#{name}".to_sym)
      end
      name = name.to_s.parameterize.tr('-', '_') unless name.is_a?(Symbol)

      @config[:layers] ||= []
      @config[:layers] << { reference: name.to_s.camelcase(:lower) }.merge(options.merge(name: name, serie: serie.to_s.camelcase(:lower)))
    end

    def simple(name, serie = name, options = {})
      layer(name, serie, options.merge(type: :simple))
    end

    # Add a serie of geo data
    def serie(name, feature_collection)
      @config[:series] ||= {}.with_indifferent_access
      @config[:series][name] = feature_collection
      # data.compact.collect do |item|
      #   next unless item[:shape]
      #   item
      #     # .merge(shape: Charta.new_geometry(item[:shape]).transform(:WGS84).to_json_object)
      #     # .merge(item[:popup] ? { popup: compile_visualization_popup(item[:popup], item) } : {})
      # end.compact
    end

    def to_json(options = {})
      @config.jsonize_keys.to_json
    end
  end
end

module CartographyHelper
  def configure_cartography(options = {})
    # config = Cartography::Configuration.new({ categories_colors: theme_colors }.merge(options))
    config = Cartography::Configuration.new(options)
    yield config
    config
  end
  def cartography( options = {}, html_options = {}, &block)
    config = configure_cartography(options, &block)
    content_tag(:div, nil, html_options.deep_merge(data: { cartography: config.to_json }))
  end
end
