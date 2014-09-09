require 'net/http'
require 'uri'

class DashboardController < ApplicationController

  THREADS = 25
  TIMEOUT_SECONDS = 30

  def view
    @user = User.find(params[:id])

    @pageTitle = @user.name + "'s Dashboard"
    @valueKeys = [ :dollarsraised, :participants, :teams ]
    @valueLabels = {
                :dollarsraised => "Dollars Raised",
                :teams => "Teams",
                :participants => "Participants"
    }

    @relayStats = Parallel.map(@user.relays, :in_threads => THREADS) { |relay| fetchPage(relay) }
    @relayStats = @relayStats.sort_by { |rstat| rstat[:date] }

    @totals = {}
    @valueKeys.each do |key|
      if @relayStats.first[key].kind_of?(StatusValue)
        @totals[key] = StatusValue.sum( @relayStats.map {|stat| stat[key]})
      end
    end
  end

  def view_all_by_user
    users = User.all()

    @pageTitle = "Overview Dashboard By Specialist"
    @valueKeys = [ :dollarsraised, :participants, :teams ]
    @valueLabels = {
                :dollarsraised => "Dollars Raised",
                :teams => "Teams",
                :participants => "Participants"
    }

    @users = users.map do |user|

      relayStats = Parallel.map(user.relays, :in_threads => THREADS) { |relay| fetchPage(relay) }
      relayStats = relayStats.sort_by { |rstat| rstat[:date] }

      totals = {}
      @valueKeys.each do |key|
        if relayStats.first[key].kind_of?(StatusValue)
          totals[key] = StatusValue.sum( relayStats.map {|stat| stat[key]})
        end
      end

      {
        :user => user,
        :relays => relayStats,
        :totals => totals
      }
    end
  end

  def view_all
    relays = Relay.all()

    @pageTitle = "Overview Dashboard"
    @valueKeys = [ :dollarsraised, :participants, :teams ]
    @valueLabels = {
                :dollarsraised => "Dollars Raised",
                :teams => "Teams",
                :participants => "Participants"
    }

    @relayStats = Parallel.map(relays, :in_threads => THREADS) { |relay| fetchPage(relay) }
    @relayStats = @relayStats.sort_by { |rstat| rstat[:date] }

    @totals = {}
    @valueKeys.each do |key|
      if @relayStats.first[key].kind_of?(StatusValue)
        @totals[key] = StatusValue.sum( @relayStats.map {|stat| stat[key]})
      end
    end
  end

  private
    def fetchPage(relay)
      data = { :relay => relay }
      goals = relay.goals

      logger.info("Fetching #{relay.url}")

      begin
        uri = URI.parse(relay.url)
        req = Net::HTTP.new(uri.host, uri.port)
        req.read_timeout = TIMEOUT_SECONDS
        res = req.start() do |http|
          http.get(uri.request_uri)
        end
logger.info(">>1")
        body = res.body
        data[:error] = "0"
        if body.nil?
          return data
        end
        data[:error] = body.length
        data[:date] = Date.today unless data[:date]
logger.info(">>2")

        body.scan(/<p id="tr-greeting-eventInfo-date">([^<]*)/) do |match|
          begin
            data[:date] = parseDate(match[0])
          rescue => ex
            logger.error("Exception parsing date for #{relay.url} [#{match[0]}]: #{ex.message}")
            data[:error] = ex.message
            data[:date] = Date.today unless data[:date]
          end
        end
logger.info(">>3")

#        section = body.scan(/<div id="tr-greeting-eventStats">\n(.*)\n/)
#        section = body.scan(/(tr-greeting-eventStats)/)
logger.info(">>4")
#        section[0][0].scan(/.*>([0-9]+) teams.*>([0-9]+) participants.*>(\$[0123456789,.]+)/) do |match|
#          data[:teams] = StatusValue.new(:teams, match[0], goals[:teams])
#          data[:participants] = StatusValue.new(:participants, match[1], goals[:participants])

#          raised = match[2]
#          raised += '.00' if !raised.include?('.')
#          data[:dollarsraised] = StatusValue.new(:dollarsraised, raised, goals[:dollarsraised])
#        end
logger.info(">>5")

        #section[0][0].scan(/<strong>([0123456789.$,]+)<\/strong>&nbsp;([^.]+)/) { |match|
        #  key = match[1].downcase.delete(" ").to_sym
        #  key = :dollarsraised if key == :raised
        #  data[key] = StatusValue.new(key, match[0], goals[key])
        #}
      rescue Timeout::Error => ex
        logger.error("Timeout fetching #{relay.url}: #{ex.message}")
        data[:error] = "Timeout"
        data[:date] = Date.today unless data[:date]
      rescue => ex
        logger.error("Exception fetching #{relay.url}: #{ex.message}")
        logger.error(ex.backtrace.join("\n"))
        data[:error] = ex.message + ex.backtrace.join("\n")
        data[:date] = Date.today unless data[:date]
      end
      logger.info("Fetched #{relay.url}")

      data
    end

    def testParseDate
      parseDate("March 28, 2014")
      parseDate("Friday, June 27 2014")
      parseDate("June 13- June 14, 2014")
      parseDate("Saturday, June 14, 2014")
      parseDate("Saturday, June 14,2014")
      parseDate("September 6,2013 5:30PM")
      parseDate("Saturday May 31st 2014 ")
    end

    def parseDate(s)
      dateStr =
        if match = /(.*)-(.*),(.*)/.match(s)
#          puts "hyphen"
          match[1].strip + " " + match[3].strip
        elsif match = /(.*),(.*),(.*)/.match(s)
#          puts "three part"
          match[2].strip + " " + match[3].strip
        elsif match = /(.*),(.*) ([0-9:]+PM)/.match(s)
#          puts "with time"
          match[1].strip + " " + match[2].strip
        elsif match = /(.*), (201[34567])/.match(s)
#          puts "comma and space before year"
          match[1].strip + " " + match[2].strip
        elsif match = /(.*),([^, ]+201[34567])/.match(s)
#          puts "no comma before year"
          match[2].strip
        elsif match = /(\w*) (\w*) (\d*)\w* (\d*)/.match(s)
#          puts "no commas with st"
          match[2].strip + " " + match[3] + " " + match[4]
        end
#      puts "    " + dateStr
      Date.strptime(dateStr, '%B %d %Y')
    end

    def debugFetchPage(url)
      uri = URI.parse(url)
      req = Net::HTTP.new(uri.host, uri.port)
      req.read_timeout = 60
      res = req.start() do |http|
        http.get(uri.request_uri)
      end

      body = res.body
      if body.nil?
        return data
      end

#      body.scan(/<p id="tr-greeting-eventInfo-date">[^,]*[-,](.*)(201[34])/) do |match|
      body.scan(/<p id="tr-greeting-eventInfo-date">([^<]*)/) do |match|
        puts match[0]
        m = match[0].sub(/.*-/, '')
        puts m
        parts = m.split(',')
        puts parts.inspect

        if parts.length == 1
          m = m.strip
        elsif parts.length == 2
          m = parts[0].strip + " " + parts[1].strip
        elsif parts.length > 2
          m = parts[parts.length-2].strip + " " + parts[parts.length-1].strip
        end

        puts m
        puts Date.strptime(m, '%B %d %Y')
      end

      section = body.scan(/<div id="tr-greeting-eventStats">\n(.*)\n/)

      section[0][0].scan(/.*>([0-9]+) teams.*>([0-9]+) participants.*>(\$[0123456789,.]+)/) do |match|
        puts match[0]
        puts match[1]
        puts match[2]
      end
    end


end
