# adapted from lee-dohm's https://github.com/lifted-studios/html-pipeline-wiki-link/blob/master/lib/html/pipeline/wiki_link/wiki_link_filter.rb

require 'html/pipeline'
require 'open-uri'

class PipelineFilter::WikiLinkFilter < HTML::Pipeline::Filter
  # An `HTML::Pipeline` filter class that detects wiki-style links and converts them to HTML links.
  # Initializes a new instance of the `WikiLinkFilter` class.
  #
  # @param doc     Document to filter.
  # @param context Parameters for the filter.
  # @param result  Results extracted from the filter.
  def initialize(doc, context = nil, result = nil)
    super(doc, context, result)

    @base_url = '/'
    @space_replacement = '_'

    if context
      @base_url = "/#{context[:entry].parent_notebook.name_with_owner}" if context[:entry]
      @space_replacement = context[:space_replacement] if context[:space_replacement]
    end

    unless @base_url.empty? || @base_url =~ /\/$/
      @base_url += '/'
    end
  end

  # Performs the translation and returns the updated text.
  # 
  # @return [String] Updated text with translated wiki links.
  def call
    html.gsub(/\[\[([^\]|]*)(\|([^\]]*))?\]\]/) do
      link = $1
      desc = $3

      notebook = context[:entry].parent_notebook

      link_identifier = link.strip.gsub(/\s+/, @space_replacement)

      if linked_entry = notebook.entries.where(identifier: link_identifier).or(notebook.entries.where(url: link)).first
        if Arquivo.static?
          entry_path = Rails.application.routes.url_helpers.entry_path(linked_entry)
        else
          entry_path = Rails.application.routes.url_helpers.entry_path(linked_entry, owner: notebook.owner, notebook: notebook)
        end

        "<a href=\"#{entry_path}\" data-wikify=\"#{linked_entry.identifier}\">#{to_description(desc || linked_entry.subject || link)}</a>"
      else
        # TODO: test color-red / usage of #s in links / link generates well
        "<a href=\"#{to_link link}\" class='color-red-5'>#{to_description(desc || link)}</a>"
      end
    end
  end

  private

  # Converts the given text into an appropriate link description.
  # 
  # @param text Proposed description text.
  # @return Updated text for use as a link description.
  # some kinda weird bug with </a><script>alert(1)</script> is rendering as
  # </a>&lt;script>alert(1)&lt;/script>
  def to_description(text)
    ERB::Util.html_escape(text).strip.gsub(/\s+/, ' ')
  end

  # Converts the given text into an appropriate link.
  # 
  # @param text Proposed link text.
  # @return Updated text to use as a link.
  def to_link(text)
    URI::encode(@base_url + text.strip.gsub(/\s+/, @space_replacement))
  end
end
