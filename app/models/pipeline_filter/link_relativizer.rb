require 'html/pipeline'

class PipelineFilter::LinkRelativizer < HTML::Pipeline::Filter

  # TODO: test his somewhat insane behaviour; needs to ignore links to other sites
  # TODO: probably needs some other optional switch?
  # TODO: needs to support stylesheets, video, audio, etc
  # i.e. https://www.w3schools.com/tags/att_src.asp / https://www.w3schools.com/tags/att_href.asp
  def call
    if !Arquivo.static? && context[:entry]
      prefix = "/#{context[:entry].parent_notebook.name_with_owner}"
      doc.css("a[href^='/']:not([href^='#{prefix}']),
              img[src^='/']:not([src^='#{prefix}'])").each do |tag|
        case tag.name
        when "a"
          attr = "href"
        when "img"
          attr = "src"
        end

        old_path = tag.attributes[attr].value
        new_path = Pathname.new(File.join(prefix, old_path)).cleanpath.to_s
        tag.attributes[attr].value = new_path
      end
    end

    doc
  end
end
