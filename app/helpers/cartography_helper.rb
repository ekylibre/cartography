module CartographyHelper
  def cartography(options = {}, html_options = {}, &block)
    config = {}
    content_tag(:div, nil, html_options.deep_merge(data: { cartography: config.to_json }))
  end
end
