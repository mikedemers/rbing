require "httparty"
require "yaml"
#
# Usage:
# 
#  bing = RBing.new("YOURAPPID")
#  
#  rsp = bing.web("ruby")
#  puts rsp.web.results[0].title
#  => "Ruby (programming language) - Wikipedia, the free encyclopedia"
#  
#  rsp = bing.web("ruby", :site => "github.com")
#  puts rsp.web.results[0].url
#  => "http://github.com/vim-ruby/vim-ruby/tree/master"
#  
#  rsp = bing.web("ruby", :site => ["github.com", "rubyforge.org"])
#  puts rsp.web.results[0].url
#  => "http://rubyforge.org/"
#  
#  rsp = bing.news("search engines")
#  puts rsp.web.results[0].title
#  => "Microsoft Bing more popular than Yahoo"
#  
#  rsp = bing.spell("coincidance")
#  puts rsp.spell.results[0].value
#  => "coincidence"
#  
#  rsp = bing.instant_answer("How many rods in a furlong?")
#  puts rsp.instant_answer.results[0].instant_answer_specific_data.encarta.value
#  => "1 furlong = 40 rods"
#
class RBing
  
  # Convenience wrapper for the response Hash.
  # Converts keys to Strings. Crawls through all
  # member data and converts any other Hashes it
  # finds. Provides access to values through
  # method calls, which will convert underscored
  # to camel case.
  #
  # Usage:
  # 
  #  rd = ResponseData.new("AlphaBeta" => 1, "Results" => {"Gamma" => 2, "delta" => [3, 4]})
  #  puts rd.alpha_beta
  #  => 1
  #  puts rd.alpha_beta.results.gamma
  #  => 2
  #  puts rd.alpha_beta.results.delta
  #  => [3, 4]
  #
  class ResponseData < Hash
  private
    def initialize(data={})
      data.each_pair {|k,v| self[k.to_s] = deep_parse(v) }
    end
    def deep_parse(data)
      case data
      when Hash
        self.class.new(data)
      when Array
        data.map {|v| deep_parse(v) }
      else
        data
      end
    end
    def method_missing(*args)
      name = args[0].to_s
      return self[name] if has_key? name
      camelname = name.split('_').map {|w| "#{w[0,1].upcase}#{w[1..-1]}" }.join("")
      if has_key? camelname
        self[camelname]
      else
        super *args
      end
    end
  end
  
  include HTTParty
  
  attr_accessor :instance_options
  
  base_uri "http://api.search.live.net/json.aspx"
  format :json
  
  BASE_OPTIONS = [:version, :market, :adult, :query, :appid, :sources]
  
  # Query Keywords: <http://help.live.com/help.aspx?project=wl_searchv1&market=en-US&querytype=keyword&query=redliub&tmt=&domain=www.bing.com:80>
  #
  QUERY_KEYWORDS = [:site, :language, :contains, :filetype, :inanchor, :inbody, :intitle, :ip, :loc, :location, :prefer, :feed, :hasfeed, :url]
  
  # Source Types: <http://msdn.microsoft.com/en-us/library/dd250847.aspx>
  #
  SOURCES = %w(Ad Image InstantAnswer News Phonebook RelatedSearch Spell Web)
  
  # Set up methods for each search source:
  # +ad+, +image+, +instant_answer+, +news+, +phonebook+, +related_search+,
  # +spell+ and +web+
  #
  # Example:
  # 
  #   bing = RBing.new(YOUR_APP_ID)
  #   bing.web("ruby gems", :count => 10)
  #
  SOURCES.each do |source|
    fn = source.to_s.gsub(/[a-z][A-Z]/) {|c| "#{c[0,1]}_#{c[1,1]}" }.downcase
    class_eval "def #{fn}(query, options={}) ; search('#{source}', query, options) ; end"
  end
  
  
  # issues a search for +query+ in +source+
  #
  def search(source, query, options={})
    rsp = self.class.get('', options_for(source, query, options))
    ResponseData.new(rsp['SearchResponse']) if rsp
  end
  
  
private
  
  
  # instantiates a new RBing client with the given +app_id+.
  # +options+ can contain values to be passed with each query.
  #
  def initialize(app_id=nil, options={})
    @instance_options = options.merge(:AppId => (app_id || user_app_id))
  end
  # constructs a query string for the given
  # +query+ and the optional query +options+
  #
  def build_query(query, options={})
    queries = []
    QUERY_KEYWORDS.each do |kw|
      next unless options[kw]
      if options[kw].is_a? Array
        kw_query = options[kw].map {|s| "#{kw}:#{s}".strip }.join(" OR ")
        queries << " (#{kw_query})"
      else
        queries << " #{kw}:#{options[kw]}"
      end
    end
    "#{query} #{queries.join(' ')}".strip
  end
  
  
  # returns +options+ with its keys converted to
  # strings and any keys in +exclude+ omitted.
  #
  def filter_hash(options, exclude=[])
    ex = exclude.inject({}) {|h,k| h[k.to_s] = true; h }
    options.inject({}) {|h,kv| h[kv[0]] = kv[1] unless ex[kv[0].to_s]; h }
  end
  
  
  # returns an options Hash suitable for passing to
  # HTTParty's +get+ method
  #
  def options_for(type, query, options={})
    opts = instance_options.merge(filter_hash(options, BASE_OPTIONS))
    opts.merge!(:sources => type.to_s, :query => build_query(query, options))
    
    source_options = filter_hash(options, [:http] + BASE_OPTIONS + QUERY_KEYWORDS)
    opts.merge!(scope_source_options(type, source_options))
    
    http_options = options[:http] || {}
    http_options.merge(:query => opts)
  end
  
  
  # returns a Hash containing the data in +options+
  # with the keys prefixed with +type+ and '.'
  #
  def scope_source_options(type, options={})
    options.inject({}) {|h,kv| h["#{type}.#{kv[0]}"] = kv[1]; h }
  end
  
  
  # returns the user's default app id, if one has been
  # defined in ~/.rbing_app_id
  #
  def user_app_id(force=false)
    @user_app_id = nil if force
    @user_app_id ||= read_user_app_id
  end
  
  
  # reads the App Id stored in ~/.rbing_app_id
  #
  def read_user_app_id
    fn = File.join(RUBY_PLATFORM =~ /mswin32/ ? ENV['USERPROFILE'] : ENV['HOME'], ".rbing_app_id")
    File.read(fn).strip if File.exists?(fn)
  end
end
