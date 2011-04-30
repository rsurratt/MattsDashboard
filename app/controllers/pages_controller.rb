require 'net/http'
require 'uri'

class PagesController < ApplicationController
  def dashboard
    @valueKeys = [ :dollarsraised, :participants, :teams ]
    @valueLabels = { :dollarsraised => "Dollars Raised",
                :teams => "Teams",
                :participants => "Participants"
    }

    @relayStats = [
      fetchPage('http://main.acsevents.org/site/TR?pg=entry&fr_id=29348', :dollarsraised => 54500, :teams => 100, :participants => 600),
      fetchPage('http://main.acsevents.org/site/TR?pg=entry&fr_id=31135',
                :dollarsraised => 57500, :teams => 100, :participants => 600),
      fetchPage('http://main.acsevents.org/site/TR?pg=entry&fr_id=31206',
                :dollarsraised => 110000, :teams => 100, :participants => 600),
      fetchPage('http://main.acsevents.org/site/TR?pg=entry&fr_id=31102',
                :dollarsraised => 65500, :teams => 100, :participants => 600)
    ]

    @totals = {}
    @valueKeys.each { |key|
      if @relayStats.first[key].kind_of?(StatusValue)
        @totals[key] = StatusValue.sum( @relayStats.map {|stat| stat[key]})
      end
    }
  end

  private
    def fetchPage(url, goals = {} )
      uri = URI.parse(url)
      res = Net::HTTP.start(uri.host, uri.port) { |http|
        http.get(uri.request_uri)
      }

      data = {}
      data[:url] = url

      body = res.body
      if body.nil?
        return data
      end

      nameMatch = body.match(/2011 Relay For Life of ([^<:]+)/)
      if nameMatch.nil?
        nameMatch = body.match(/2011 ([^<:]+) Relay For Life/)
      end
      data[:name] = nameMatch[1]

      body.scan(/<span id=.rotating_progress\d+.>\n([^:]+): &nbsp;([^\n]+)/) { |match|
        key = match[0].downcase.delete(" ").to_sym
        data[key] = StatusValue.new(key, match[1], goals[key])
      }

      return data
    end
end


class StatusValue
  attr_accessor :label, :sval, :ival, :goal, :percent_of_goal, :is_money

  def initialize(_label, _sval, _goal)
    self.label = _label
    self.sval = _sval
    self.is_money = _sval.include?("$")
    self.ival = _sval.delete("$., ").to_i
    self.goal = _goal

    if is_money
      _goal = goal * 100  # money ivals are in cents, goal in dollar
    end
    if _goal > 0
      self.percent_of_goal = (ival.to_f / _goal * 100).to_i
    end
  end

  def self.sum(values)
    if values.nil? || values.empty?
      return nil
    end

    sum_ival = 0
    sum_goal = 0
    label = ''
    is_money = false

    values.each { |value|
      label = value.label
      sum_ival = sum_ival + value.ival
      sum_goal = sum_goal + value.goal
      is_money = is_money || value.is_money
    }

    if is_money
      sval = format_dollars(sum_ival)
    else
      sval = sum_ival.to_s
    end

    StatusValue.new(label, sval, sum_goal)
  end

  private
    def self.format_dollars(n)
      s = '%.2f' % (n.to_f / 100.0)
      '$' + s.gsub(/(\d)(?=\d{3}+(?:\.|$))(\d{3}\..*)?/,'\1,\2')
    end
end