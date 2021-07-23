
=begin
class Sasser
  def initialize
    @env = Rails.application.assets
  end

  def render(template)

    input = {
      data: File.read("app/assets/stylesheets/application.css.scss"),
      environment: Rails.application.assets,
      metadata: {
        dependencies: Set.new,
        required: Set.new,
        stubbed: Set.new,
        links: Set.new,
        to_load: Set.new,
        to_link: Set.new,
      },
      cache: false,
      filename: "filename",
      load_path: "/Users/phillmv/code/ok/archive/app/assets/stylesheets",
      name: "application",
      content_type: "text/css"
    }

    SassC::Rails::ScssTemplate.new.render(input)

    context = Rails.application.assets.context_class.new(input)

    SassC::Engine.new(input[:data], 
                      input.merge(syntax: :scss,
                                  load_paths: input[:environment].paths,
                                  sprockets: {
                                    context: context,
                                    environment: input[:environment],
                                    dependencies: context.metadata[:dependency_paths]
                                  })
                     )

                      {
      filename: "filename",
      line_comments: true,
      syntax: :scss,
      load_paths: Rails.application.assets.paths,
      importer: SassC::Rails::Importer,
      sprockets: {
        context: Rails.application.assets,
        
    SassC::Engine.new(s, {
      syntax: :scss,
      cache: false,
      read_cache: false,
      load_paths: Rails.application.assets.paths,
      
    }).render
  end
end

input is
SassC::Rails::ScssTemplate.new

{data: "string of sass",
  :metadata=>
  {:dependencies=>
    #<Set: {"environment-version",
     "environment-paths",
     "rails-env",
     "processors:type=text/css&file_type=text/scss&pipeline=self",
     "file-digest:///Users/phillmv/code/ok/archive/app/assets/stylesheets/application.css.scss"}>,
   :required=>#<Set: {}>,
   :stubbed=>#<Set: {}>,
   :links=>#<Set: {}>,
   :to_load=>#<Set: {}>,
   :to_link=>#<Set: {}>},
 :environment=>
   #<Sprockets::CachedEnvironment:0x3fe2f1085908 root="/Users/phillmv/code/ok/archive", paths=["/Users/phillmv/code/ok/archive/app/assets/config", "/Users/phillmv/code/ok/archive/app/assets/images", "/Users/phillmv/code/ok/archive/app/assets/stylesheets", "/Users/phillmv/code/ok/archive/lib/assets/git_defaults", "/Users/phillmv/.gem/ruby/2.6.5/gems/simple_calendar-2.3.0/app/assets/stylesheets", "/Users/phillmv/.gem/ruby/2.6.5/gems/neat-1.7.4/app/assets/stylesheets", "/Users/phillmv/.gem/ruby/2.6.5/gems/actioncable-6.0.2.1/app/assets/javascripts", "/Users/phillmv/.gem/ruby/2.6.5/gems/activestorage-6.0.2.1/app/assets/javascripts", "/Users/phillmv/.gem/ruby/2.6.5/gems/actionview-6.0.2.1/lib/assets/compiled", "/Users/phillmv/.gem/ruby/2.6.5/gems/turbolinks-source-5.2.0/lib/assets/javascripts", "/Users/phillmv/.gem/ruby/2.6.5/gems/bourbon-7.0.0/core", "/Users/phillmv/code/ok/archive/node_modules"]>,
 :cache=>
  #<Sprockets::Cache local=#<Sprockets::Cache::MemoryStore size=19/1024> store=#<Sprockets::Cache::FileStore size=50450970/52428800>>,
 :uri=>
  "file:///Users/phillmv/code/ok/archive/app/assets/stylesheets/application.css.scss?type=text/css&pipeline=self",
 :filename=>"/Users/phillmv/code/ok/archive/app/assets/stylesheets/application.css.scss",
 :load_path=>"/Users/phillmv/code/ok/archive/app/assets/stylesheets",
 :name=>"application",
 :content_type=>"text/css"}


where does the cachedenvironment come from?
=end

SassC::Engine.new(allscss, {
  filename: "all.css.scss",
  syntax: :scss,
  load_paths: ["/Users/phillmv/code/ok/test-archive/blog_source/stylesheets"],
  
})
