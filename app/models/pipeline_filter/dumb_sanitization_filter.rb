# sole purpose of this class is to run the sanitization filter a 2nd time
# in the same pipeline, but with a different whitelist
class PipelineFilter::DumbSanitizationFilter < HTML::Pipeline::SanitizationFilter
  def whitelist
    context[:second_whitelist]
  end
end

