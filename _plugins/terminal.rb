require 'cgi'

module Jekyll
  class TerminalBlock < Liquid::Block
    SYNTAX = /^([a-zA-Z0-9.+#-]+)((\s+\w+(=(\w+|"([0-9]+\s)*[0-9]+"))?)*)$/

    def initialize(tag_name, markup, tokens)
      super
      if markup.strip =~ SYNTAX
        @prompt = $1.downcase
      else
        raise SyntaxError.new <<-eos
Syntax Error in tag 'terminal' while parsing the following markup:
#{markup}
Valid syntax: terminal <prompt>
eos
      end
    end

    def render(context)
      content = super
      "<pre class=\"terminal\">\n<span class=\"prompt\">#{@prompt}</span>#{CGI::escapeHTML(content)}</pre>"
    end
  end
end
Liquid::Template.register_tag('terminal', Jekyll::TerminalBlock)
