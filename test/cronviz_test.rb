require 'lib/crontab'
require 'lib/cron_job'
require 'lib/cron_parser'

EARLIEST_TIME =  "2011-10-11 00:00"
LATEST_TIME   = "2011-10-12 00:00"

describe Cronviz::Crontab do
  def init_crontab options
    event_data = {:default => {}, :every_minute => {}, :every_five_minutes => {}}
    @options = {
      :earliest_time=>EARLIEST_TIME,
      :latest_time=>LATEST_TIME,
      :event_data=>event_data
    }
    crontab = Cronviz::Crontab.new @options.merge options
  end
  
  it "should generate dates no earlier than EARLIEST_TIME" do
    crontab = init_crontab :input => "17 */3 11 10 * do_some_stuff"
    crontab.jobs[0].times[0].strftime("%Y-%m-%d %H:%M").should_not < EARLIEST_TIME
  end
  it "should generate dates no later than LATEST_TIME" do
    crontab = init_crontab :input => "17 */3 */2 * * do_some_stuff"
    crontab.jobs[0].times[-1].strftime("%Y-%m-%d %H:%M").should_not > LATEST_TIME
  end

  it "should generate dates respecting day-of-week field" do
    crontab = init_crontab(:earliest_time=> "2011-10-06 00:00",
                           :latest_time  => "2011-10-17 23:59",
                           :input        => "0 17 * * 4,5 launch_happy_hour")
    crontab.jobs[0].times.count.should == 4
  end

  it "should handle single strings properly" do
    crontab = init_crontab :input => "*/5 5,6,7 11 10 2 do_some_stuff"
    crontab.jobs.count.should == 1
    crontab.jobs[0].times.count.should == 36
  end
  it "should handle multiple strings properly" do
    crontab = init_crontab :input => "17-21 */3 11 10 * do_some_stuff\n* * 11 10 * do_other_stuff"
    crontab.jobs.count.should == 2
    crontab.jobs[0].times.count.should == 40
    crontab.jobs[1].times.count.should == 1440
  end

  it "should rollup every-minute jobs" do
    crontab = init_crontab :input => "* * * * * run_every_minute"
    crontab.jobs[0].events.count.should == 1
  end
  it "should rollup every-five-minute jobs" do
    crontab = init_crontab :input => "*/5 * * * * run_every_five_minute"
    crontab.jobs[0].events.count.should == 1
  end
  it "should not rollup every-six-minute jobs" do
    crontab = init_crontab :input => "*/6 * * * * run_every_five_minute"
    crontab.jobs[0].events.count.should == 241
  end
  it "should rollup every-minute jobs when the graph period is a few minutes" do
    crontab = init_crontab(:earliest_time => "2011-10-11 00:00",
                           :latest_time   => "2011-10-11 00:08",
                           :input         => "* * * * * run_every_minute")
    crontab.jobs[0].events.count.should == 1
  end
  it "should rollup every-five-minute jobs when the graph period is a few hours" do
    crontab = init_crontab(:earliest_time => "2011-10-11 00:01",
                           :latest_time   => "2011-10-11 02:59",
                           :input         => "*/5 * * * * run_every_five_minutes")
    crontab.jobs[0].events.count.should == 1
  end
  it "should rollup every-minute jobs when the graph period is a few days" do
    crontab = init_crontab(:earliest_time => "2011-10-11 00:00",
                           :latest_time   => "2011-10-13 00:12",
                           :input         => "* * * * * run_every_minute")
    crontab.jobs[0].events.count.should == 1
  end
  it "should rollup every-five-minute jobs when the graph period is a few days" do
    crontab = init_crontab(:earliest_time => "2011-10-11 00:00",
                           :latest_time   => "2011-10-12 12:59",
                           :input         => "*/5 * * * * run_every_five_minutes")
    crontab.jobs[0].events.count.should == 1
  end
  it "should skip jobs that are broken" do
    crontab = init_crontab :input => "17 */3 11 10 frob do_some_stuff"
    crontab.jobs.empty?.should be_true
  end
  it "should not truncate the command" do
    crontab = init_crontab :input => "17 */3 11 10 6 do_some_stuff"
    crontab.jobs[0].command.should eq("do_some_stuff")
  end

  it "should not remove spaces in commands" do
    crontab = init_crontab :input => "17 */3 11 10 6 things and other things"
    crontab.jobs[0].command.should eq("things and other things")
  end

  it "should work with @yearly" do
    crontab = init_crontab(:earliest_time => "2011-12-01 00:00",
                           :latest_time   => "2013-01-31 23:59",
                           :input => "@yearly sing_auld_lang_syne")
    crontab.jobs.empty?.should be_false
    crontab.jobs[0].events.count.should == 2
  end
  it "should work with @annually" do
    crontab = init_crontab(:earliest_time => "2011-12-01 00:00",
                           :latest_time   => "2013-01-31 23:59",
                           :input => "@annually pay_taxes")
    crontab.jobs.empty?.should be_false
    crontab.jobs[0].events.count.should == 2
  end
  it "should work with @monthly" do
    crontab = init_crontab(:earliest_time => "2011-12-01 00:00",
                           :latest_time   => "2012-06-31 23:59",
                           :input => "@monthly test_smoke_detector")
    crontab.jobs.empty?.should be_false
    crontab.jobs[0].events.count.should == 7
  end
  it "should work with @weekly" do
    crontab = init_crontab(:earliest_time => "2012-06-01 00:00",
                           :latest_time   => "2012-06-30 23:59",
                           :input => "@weekly take_out_the_trash")
    crontab.jobs.empty?.should be_false
    crontab.jobs[0].events.count.should == 4
  end
  it "should work with @daily" do
    crontab = init_crontab(:earliest_time => "2012-06-01 00:00",
                           :latest_time   => "2012-06-30 23:59",
                           :input => "@daily get_a_good_nights_sleep")
    crontab.jobs.empty?.should be_false
    crontab.jobs[0].events.count.should == 30
  end
  it "should work with @midnight" do
    crontab = init_crontab(:earliest_time => "2012-06-01 00:00",
                           :latest_time   => "2012-06-30 23:59",
                           :input => "@midnight and_dream_of_sheep")
    crontab.jobs.empty?.should be_false
    crontab.jobs[0].events.count.should == 30
  end
  it "should work with @hourly" do
    crontab = init_crontab(:earliest_time => "2012-06-01 00:00",
                           :latest_time   => "2012-06-01 23:59",
                           :input => "@hourly elevate_the_lepnitzivator")
    crontab.jobs.empty?.should be_false
    crontab.jobs[0].events.count.should == 24
  end
  it "should skip jobs with unknown shorthand" do
    crontab = init_crontab(:earliest_time => "2012-06-01 00:00",
                           :latest_time   => "2012-06-01 23:59",
                           :input => "@slowly lower_the_gun_to_the_floor")
    crontab.jobs.empty?.should be_true
  end
end


describe Cronviz::CronParser do
  before(:all) do
    @parser = Cronviz::CronParser
  end

  it "should expand a minute to a single iterable value" do
    @parser.expand(:mi, "17").should == [17]
  end
  it "should expand an hour to a single iterable value" do
    @parser.expand(:ho, "3").should == [3]
  end

  it "should expand a set of minutes to two values" do
    @parser.expand(:mi, "16,46").should == [16,46]
  end
  it "should expand a set of hours to three values" do
    @parser.expand(:ho, "3,6,9").should == [3,6,9]
  end

  it "should expand a range of minutes to a range of values" do
    @parser.expand(:mi, "1-5").should == [1,2,3,4,5]
  end
  it "should expand a range of hours to a range of values" do
    @parser.expand(:ho, "12-23").should == [12,13,14,15,16,17,18,19,20,21,22,23]
  end

  it "should expand all minutes to 60 minutes" do
    @parser.expand(:mi, "*").should == (0..59).to_a
  end
  it "should expand all hours to 24 hours" do
    @parser.expand(:ho, "*").should == (0..23).to_a
  end

  it "should expand all days to 31 days, 1-indexed" do
    @parser.expand(:da, "*").should == (1..31).to_a
  end
  it "should expand all months to 12 months, 1-indexed" do
    @parser.expand(:mo, "*").should == (1..12).to_a
  end

  it "should expand every X minutes to the proper values" do
    @parser.expand(:mi, "*/13").should == [0, 13, 26, 39, 52]
  end
  it "should expand every X hours to the proper values" do
    @parser.expand(:ho, "*/11").should == [0, 11, 22]
  end
  it "should expand every 13 hours to 0 and 13" do
    @parser.expand(:ho, "*/13").should == [0, 13]
  end
  it "should expand every 5 days to be one-indexed" do
    @parser.expand(:da, "*/5").should == [1, 6, 11, 16, 21, 26, 31]
  end
  it "should expand every 2 months to be one-indexed" do
    @parser.expand(:mo, "*/2").should == [1, 3, 5, 7, 9, 11]
  end

  it "should expand named months" do
    @parser.expand(:mo, "dec").should == [12]
  end
  it "should expand ranges of named months" do
    @parser.expand(:mo, "jul-nov").should == [7,8,9,10,11]
  end
  it "should not matter what case the named month is" do
    @parser.expand(:mo, "Jan-MAR").should == [1,2,3]
  end
  it "should expand named days of the week" do
    @parser.expand(:dw, "wed").should == [3]
  end
  it "should expand ranges of named days of the week" do
    @parser.expand(:dw, "thu-sat").should == [4,5,6]
  end
  it "should not matter what case the named day of the week is" do
    @parser.expand(:dw, "Sun-TUE").should == [0,1,2]
  end

  it "should raise if weird things show up for days of week" do
    expect { @parser.expand(:dw, "bar") }.to raise_error
    expect { @parser.expand(:dw, "quux") }.to raise_error
  end
  it "should raise if weird things show up for month" do
    expect { @parser.expand(:mo, "foo") }.to raise_error
    expect { @parser.expand(:mo, "frob") }.to raise_error
  end

  it "should raise if month is in minute, hour, or days" do
    expect { @parser.expand(:mi, "bar") }.to raise_error
    expect { @parser.expand(:ho, "baz") }.to raise_error
    expect { @parser.expand(:da, "bat") }.to raise_error
  end


end
