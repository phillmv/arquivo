require 'test_helper'

class UrlNormalizerTest < ActiveSupport::TestCase
  test "google docs are normalized" do
    base_url = "https://docs.google.com/document/d/1E-V2Qj2OhURTtHVo9ONDjteHS7fRr77lEBbttA6DbIo/edit"

    # we strip heading links
    assert_equal base_url, normal("https://docs.google.com/document/d/1E-V2Qj2OhURTtHVo9ONDjteHS7fRr77lEBbttA6DbIo/edit#heading=h.wwc00h4un5en")

    # we strip vacant fragments
    assert_equal base_url, normal("https://docs.google.com/document/d/1E-V2Qj2OhURTtHVo9ONDjteHS7fRr77lEBbttA6DbIo/edit#")
  end

  test "github pull request links are normalized" do
    base_url = "https://github.com/github/cmark-gfm/pull/230"

    # we strip /files"

    assert_equal base_url, normal("https://github.com/github/cmark-gfm/pull/230/files")

    # we strip everything after /files, in fact
    # (I don't think I care to bookmark specific lines in a PR :thinking:, tho
    # this may come back to bite me)
    assert_equal base_url, normal("https://github.com/github/cmark-gfm/pull/230/files#diff-f591fdd7c1b87d4012ee55f727e5b636755001bbc0589076d3da004c9a031eb8R51-R63")
  end

  test "does not fuck with non pull request github urls" do
    base_url = "https://github.com/github/cmark-gfm/issues/314#issue-1629534188"

    assert_equal base_url, normal("https://github.com/github/cmark-gfm/issues/314#issue-1629534188")
  end

  def normal(s)
    UrlNormalizer.new(s).to_s
  end
end
