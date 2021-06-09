#!/usr/bin/env ruby
# frozen_string_literal: true

require 'env'
require 'colorize'
require 'json'
require 'set'
require 'pry'
require 'io/console'

rows,cols = IO.console.winsize
colors = ""
count = 0
$BASE_PATHS = Regexp.new "/bin|/Users|/sbin|/home|/var|/opt|/mnt|/usr|:/|/boot|/etc|/dev|/lib|/tmp|/run|/sys"
String.colors.each do |c|
    colors = "#{colors} #{c.to_s.colorize(c)}"
    colors = "#{colors}, " if c != String.colors.last
    if count >= 5
        count = 0
        colors = "#{colors}\n    "
    else
        count = count + 1
    end
end

HELP = <<ENDHELP
  Usage: 
    colorenv -s
    colorenv -C <color> -c <color> envar1 envar2 envar3
    colorenv -j envar1 envar2 envar3

  Options:
    -j, --to-json             Outputs to JSON (no color) so you can pipe to jq if you want
    -s, --sort                Sorts the environment keys (a-z)
    -v, --value               Returns just the value (with icon, or use -i to supress the icon)
    -c, -vc, --value-color    Specifices the color to use for values
    -C, -kc, --key-color      Specifices the color to use for keys
    -p, --path-expand         Turns on path expansion
    -i, --no-icon             Turns off the icon

  Available Colors:
    #{colors}

  Help:
    -h, --help              Show's this help message
ENDHELP

def var_to_json(arg)
    "\"#{arg}\": #{ENV[arg].to_json}"
end

def print_var(args, key, max_key_len)
    k = key.ljust(max_key_len,' ').bold.colorize(args[:kc].to_sym)
    v = ENV[key].colorize(args[:vc].to_sym)
    "#{args[:icon]} #{k}#{args[:string_icon]}#{v}"
end

def pretty_path(args, key, max_key_len)
    path = ENV[key].split(':')
    k = key.ljust(max_key_len,' ')
    ck = k.bold.colorize(args[:kc].to_sym) 
    out_str = "#{args[:icon]} #{ck}"
    path.each do |p|
        cp = p.colorize(args[:vc].to_sym)
        if p.match?($BASE_PATHS)
            out_str = "#{out_str}#{args[:folder_icon]} #{cp}"
        else
            out_str = "#{out_str}#{args[:unknown_icon]} #{cp}"
        end
        
        out_str = "#{out_str}#{"\n".ljust(k.length+4,' ')}" unless p == path.last
    end
    out_str
end

def json_output(keys)
    out = "{"
    keys.each do |key|
        next unless ENV[key]
        out = "#{out} #{var_to_json(key)}"
        out = "#{out}, " unless keys.last == key
    end
    out = out + "}"
    puts out
end

def pretty_output(args, vars)
    out = ""
    max_key_len = ENV.keys.max_by(&:length).length+2
    vars.each do |key|
        next unless ENV[key]
        path_name = Regexp.new "/?PATH?"
        is_path = false
        if key.match(path_name) || ENV[key].match?($BASE_PATHS)
            is_path = true
        end
        if is_path && args[:path]
            out = "#{out}#{pretty_path(args, key, max_key_len)}\n"
        else
            out = "#{out}#{print_var(args,key,max_key_len)}\n"
        end
    end
    puts(out)
end

def parse_to_regex(str)
    escaped = Regexp.escape(str).gsub('\*','.*?')
    Regexp.new "^#{escaped}$", Regexp::IGNORECASE
  end

def match_vars(vars)
    matched_vars = Set[]
    vars.each do |v|
        regex = parse_to_regex(v)
        matches = ENV.keys.select{|i| i[regex]}
        matched_vars.merge(matches)
    end
    matched_vars.to_a
end

def sort_output(args, vars)
    if vars.size == 0
        vars = ENV.keys
    else
        vars = match_vars(vars)
    end
    
    if args[:sort]
        vars = vars.sort
    end

    if args[:json_out]
        json_output(vars)
    else
        pretty_output(args, vars)
    end
end

json_out = false
vars = Set[]
args = { :json_out => false, :vc => "blue", :kc => "green", :icon => " ", :folder_icon => " ",
         :string_icon => "識 ", :unknown_icon => "ﴕ ", :eq_icon => "", :path => false, :sort => false }
unflagged_args = []
next_arg = unflagged_args.first

icon = "" if ENV['NF_SAFE'] == "false"
args[:path] = true if ENV['PATH_EXPANSION'] == "true"
args[:vc] = ENV['VALUE_COLOR'] if ENV['VALUE_COLOR']
args[:kc] = ENV['KEY_COLOR'] if ENV['KEY_COLOR']
args[:sort] = true if ENV['SORT_ENVARS'] == "true"

ARGV.each do |arg|
    case arg
        when "-j", "--to-json" then args[:json_out] = true
        when "-c", "-vc", "--value-color" then next_arg = :vc
        when "-C", "-kc", "--key-color" then next_arg = :kc
        when "-i", "--no-icon" then
            args[:icon] = ""
            args[:folder_icon] = ""
        when "-p", "--path-expand" then args[:path] = true
        when "-s", "--sort" then args[:sort] = true
        when "-h", "--help" then
            puts HELP
            exit 0
        else
            if next_arg
                args[next_arg] = arg
                unflagged_args.delete( next_arg )
            else
                vars.merge(arg.upcase.split(' '))
            end
            next_arg = unflagged_args.first
    end
end

sort_output(args, vars.to_a)