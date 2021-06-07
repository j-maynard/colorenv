#!/usr/bin/env ruby
# frozen_string_literal: true

require 'env'
require 'colorize'
require 'json'
require 'set'

colors = ""
count = 0
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
    colorenv -v <color> -k <color> envar1 envar2 envar3
    colorenv -j envar1 envar2 envar3

  Options:
    -j, --to-json             Outputs to JSON (no color) so you can pipe to jq if you want
    -v, -vc, --value-color    Specifices the color to use for values
    -k, -kc, --key-color      Specifices the color to use for keys
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

def print_var(args, key)
    k = key.bold.colorize(args[:kc].to_sym) 
    v = ENV[key].colorize(args[:vc].to_sym)
    if key == "PATH" && args[:path]
        pretty_path(args)
    else
        "#{args[:icon]} #{k} = #{v}"
    end
end

def pretty_path(args)
    path = ENV['PATH'].split(':')
    title_len = "#{args[:icon]} PATH = ".size
    out_str = "#{args[:icon]} #{"PATH".colorize(args[:kc].to_sym)} = "
    path.each do |p|
        if p == path.last
            out_str = out_str + p.colorize(args[:vc].to_sym)
        else
            out_str = out_str + p.colorize(args[:vc].to_sym) + "%-#{title_len+1}.#{title_len+1}s" % "\n"
        end
    end
    out_str
end

def json_output(keys)
    out = "{"
    keys.each do |key|
        next unless ENV[key]
        if keys.last == key
            out = out + var_to_json(key)
        else
            out = out + var_to_json(key) + ","
        end
    end
    out = out + "}"
    puts out
end

def pretty_output(args, vars)
    out = ""
    vars.each do |key|
        next unless ENV[key]
        out = out + print_var(args, key) + "\n"
    end
    puts(out)
end

def sort_output(args, vars)
    vars = ENV.keys if vars.size == 0
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
args = { :json_out => false, :vc => "blue", :kc => "green", :icon => " ", :path => false, :sort => false }
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
        when "-v", "-vc", "--value-color" then next_arg = :vc
        when "-k", "-kc", "--key-color" then next_arg = :kc
        when "-i", "--no-icon" then args[:icon] = ""
        when "-p", "--path-expand" then args[:path] = true
        when "-n", "--no-sort" then args[:sort] = false
        when "-h", "--help" then
            puts HELP
            exit 0
        else
            if next_arg
                args[next_arg] = arg
                unflagged_args.delete( next_arg )
            else
                vars.add(arg.upcase)
            end
            next_arg = unflagged_args.first
    end
end

sort_output(args, vars.to_a)