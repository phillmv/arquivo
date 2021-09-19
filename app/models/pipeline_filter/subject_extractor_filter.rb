class PipelineFilter::SubjectExtractorFilter < HTML::Pipeline::Filter
  def call
    subject = doc.children[0..3].css("h1, h2").first

    if subject
      result[:entry_subject] = subject.text
      result[:entry_subject_html] = subject.to_s
      if context[:remove_subject]
        subject.remove
      end
    end

    doc
  end
end
