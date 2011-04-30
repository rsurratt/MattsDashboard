require 'net/http'
require 'uri'

class PagesController < ApplicationController
  def dashboard
    @relayStats = [
      fetchPage('http://main.acsevents.org/site/TR?pg=entry&fr_id=29348', 54500, 100, 600),
      fetchPage('http://main.acsevents.org/site/TR?pg=entry&fr_id=31135', 57500, 100, 600),
      fetchPage('http://main.acsevents.org/site/TR?pg=entry&fr_id=31206', 110000, 100, 600),
      fetchPage('http://main.acsevents.org/site/TR?pg=entry&fr_id=31102', 65500, 100, 600)
    ]

    @totals = { :raised => 0.to_r, :teams => 0, :participants => 0, :raisedgoal => 0, :teamsgoal => 0, :partsgoal => 0 }
    @relayStats.each { |relayStat|
      @totals[:raised] = @totals[:raised] + relayStat[:raised]
      @totals[:teams] = @totals[:teams] + relayStat[:teams].to_i
      @totals[:participants] = @totals[:participants] + relayStat[:participants].to_i

      @totals[:raisedgoal] = @totals[:raisedgoal] + relayStat[:raisedgoal]
      @totals[:teamsgoal] = @totals[:teamsgoal] + relayStat[:teamsgoal]
      @totals[:partsgoal] = @totals[:partsgoal] + relayStat[:partsgoal]
    }

    @totals[:dollarsraised] = format_dollars(@totals[:raised])
    @totals[:raisedgoalpercent] = (@totals[:raised].to_f / @totals[:raisedgoal] * 100).to_i
    @totals[:teamsgoalpercent] = (@totals[:teams].to_f / @totals[:teamsgoal] * 100).to_i
    @totals[:partsgoalpercent] = (@totals[:participants].to_f / @totals[:partsgoal] * 100).to_i


  end

  private
    def fetchPage(url, rgoal, tgoal, pgoal)
      uri = URI.parse(url)
      res = Net::HTTP.start(uri.host, uri.port) { |http|
        http.get(uri.request_uri)
      }

      data = {}
      data[:url] = url
      data[:raisedgoal] = rgoal
      data[:teamsgoal] = tgoal
      data[:partsgoal] = pgoal

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
        data[key] = match[1]
      }

      if !data[:dollarsraised].nil?
        data[:raised] = data[:dollarsraised].delete("$, ").to_r
        data[:raisedgoalpercent] = (data[:raised] / rgoal * 100).to_i
      end

      if !data[:teams].nil?
        data[:teamsgoalpercent] = (data[:teams].to_f / tgoal * 100).to_i
      end

      if !data[:participants].nil?
        data[:partsgoalpercent] = (data[:participants].to_f / pgoal * 100).to_i
      end

      return data
    end

   def format_dollars(n)
     s = '%.2f' % n.to_f
     '$' + s.gsub(/(\d)(?=\d{3}+(?:\.|$))(\d{3}\..*)?/,'\1,\2')
   end

end
