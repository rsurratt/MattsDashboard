require 'net/http'
require 'uri'

class DashboardController < ApplicationController
  def view
    @user = User.find(params[:id])

    @pageTitle = @user.name + "'s Dashboard"
    @valueKeys = [ :dollarsraised, :participants, :teams ]
    @valueLabels = {
                :dollarsraised => "Dollars Raised",
                :teams => "Teams",
                :participants => "Participants"
    }

    @relayStats = @user.relays.map { |relay| fetchPage(relay) }

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

      uri = URI.parse(relay.url)
      req = Net::HTTP.new(uri.host, uri.port)
      req.read_timeout = 60
      res = req.start() do |http|
        http.get(uri.request_uri)
      end

      body = res.body
      if body.nil?
        return data
      end

      section = body.scan(/<div id="tr-greeting-eventStats">\n(.*)\n/)

      section[0][0].scan(/.*>([0-9]+) teams.*>([0-9]+) participants.*>(\$[0123456789,.]+)/) do |match|
        data[:teams] = StatusValue.new(:teams, match[0], goals[:teams])
        data[:participants] = StatusValue.new(:participants, match[1], goals[:participants])
        data[:dollarsraised] = StatusValue.new(:dollarsraised, match[2], goals[:dollarsraised])
      end

      #section[0][0].scan(/<strong>([0123456789.$,]+)<\/strong>&nbsp;([^.]+)/) { |match|
      #  key = match[1].downcase.delete(" ").to_sym
      #  key = :dollarsraised if key == :raised
      #  data[key] = StatusValue.new(key, match[0], goals[key])
      #}

      data
    end

end
