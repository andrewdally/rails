module ActionController
  # Rewrites URLs for Base.redirect_to and Base.url_for in the controller.

  class UrlRewriter #:nodoc:
    RESERVED_OPTIONS = [:anchor, :params, :only_path, :host, :protocol]
    def initialize(request, parameters)
      @request, @parameters = request, parameters
    end
    
    def rewrite(options = {})      
      rewrite_url(rewrite_path(options), options)
    end

    def to_str
  		"#{@request.protocol}, #{@request.host_with_port}, #{@request.path}, #{@parameters[:controller]}, #{@parameters[:action]}, #{@request.parameters.inspect}"
    end

    alias_method :to_s, :to_str

    private
      def rewrite_url(path, options)
      
        rewritten_url = ""
        rewritten_url << (options[:protocol] || @request.protocol) unless options[:only_path]
        rewritten_url << (options[:host] || @request.host_with_port) unless options[:only_path]

        rewritten_url << @request.relative_url_root.to_s
        rewritten_url << path
        rewritten_url << "##{options[:anchor]}" if options[:anchor]

        return rewritten_url
      end

      def rewrite_path(options)
        options = options.symbolize_keys
        options.update((options[:params] || {}).symbolize_keys)
        RESERVED_OPTIONS.each {|k| options.delete k}
        
        path, extras = Routing::Routes.generate(options, @request)
        path = "/#{path.join('/')}".chomp '/'
        path = '/' if path.empty?
        path += build_query_string(extras)
        
        return path
      end

      # Returns a query string with escaped keys and values from the passed hash. If the passed hash contains an "id" it'll
      # be added as a path element instead of a regular parameter pair.
      def build_query_string(hash)
        elements = []
        query_string = ""
        
        hash.each do |key, value|
          key = key.to_s
          key = CGI.escape key
          key += '[]' if value.class == Array
          value = [ value ] unless value.class == Array
          value.each { |val| elements << "#{key}=#{Routing.extract_parameter_value(val)}" }
        end
        
        query_string << ("?" + elements.join("&")) unless elements.empty?
        return query_string
      end
  end
end
