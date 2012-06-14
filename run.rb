require 'rubygems'
require 'json'
require 'haml'
require 'time'

require 'lib/crontab'
require 'lib/cron_job'
require 'lib/cron_parser'

require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'pp'

EVENT_DATA = {
  :default => {
    "color"       => "#7FFFD4",
    "textColor"   => "#000000",
    "classname"   => "default",
    "durationEvent" => false},

  :every_minute => {
    "title_prefix"  => "Every minute: ",
    "color"         => "#f00",
    "durationEvent" => true},

  :every_five_minutes => {
    "title_prefix"  => "Every five minutes: ",
    "color"         => "#fa0",
    "durationEvent" => true}
}


def main

  # The options specified on the command line will be collected in *options*.
  # We set default values here.
  options = OpenStruct.new
  options.input_file = "crontab"
  options.output_file = "cronviz.html"
  options.start_time = Time.now
  options.duration = 24

  opts = OptionParser.new do |opts|
    opts.banner = "Usage: run.rb [options]"

    opts.on("-i", "--input [FILE]", String, "Input file in standard crontab format (default: 'crontab')") do |input_file|
      options.input_file = input_file
    end

    opts.on("-o", "--output [FILE]", String, "Output HTML filename (default: 'cronviz.html')") do |output_file|
      options.output_file = output_file
    end

    opts.on("-t", "--start-time [TIME]", Time, "Begin execution at given time (default: now)") do |time|
      options.start_time = time
    end

    opts.on("-d", "--duration [hours]", Integer, "Generate n hours of data (default: 24)") do |hours|
      options.duration = hours
    end

    opts.on_tail("-h", "--help", "Show this message") do
      puts opts
      exit 1
    end
  end

  begin
    opts.parse!(ARGV)
  rescue OptionParser::ParseError => ex
    puts ex.reason
    puts opts
    exit 1
  end

  earliest_time = options.start_time.strftime("%Y-%m-%d %H:%M")
  latest_time   = (options.start_time + (3600 * options.duration)).strftime("%Y-%m-%d %H:%M")

  begin
    crontab = Cronviz::Crontab.new(
      :input_file => options.input_file,
      :earliest_time => earliest_time,
      :latest_time => latest_time,
      :event_data => EVENT_DATA)
  rescue RuntimeError => ex
    puts "Fatal error: #{ex}"
    exit 1
  end

  haml = open("assets/container.haml").read

  html = Haml::Engine.new(haml).render(Object.new,
                                       :earliest_time => earliest_time,
                                       :latest_time   => latest_time,
                                       :cron_json     => crontab.to_json)

  open(options.output_file, "w") do |f|
    f.write html
  end
  puts "#{options.output_file} successfully created!"

end

main()
