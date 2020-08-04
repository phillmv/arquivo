module PipelineFilter
  # we just want to tweak the default whitelist a little bit
  # and allow the data-sourcepos attribute to go thru
  ENTRY_SANITIZATION_WHITELIST = HTML::Pipeline::SanitizationFilter::WHITELIST.dup
  ESW = ENTRY_SANITIZATION_WHITELIST
  ESW[:attributes] = ESW[:attributes].dup
  ESW[:attributes][:all] = ESW[:attributes][:all].dup
  ESW[:attributes][:all].push("data-sourcepos")
end
