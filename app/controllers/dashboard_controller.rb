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

      body.scan(/<p id="tr-greeting-eventInfo-date">.*, (.*, 201[34])/) do |match|
        data[:date] = Date.strptime(match[0], '%B %d, %Y')
      end

      section = body.scan(/<div id="tr-greeting-eventStats">\n(.*)\n/)

      section[0][0].scan(/.*>([0-9]+) teams.*>([0-9]+) participants.*>(\$[0123456789,.]+)/) do |match|
        data[:teams] = StatusValue.new(:teams, match[0], goals[:teams])
        data[:participants] = StatusValue.new(:participants, match[1], goals[:participants])

        raised = match[2]
        raised += '.00' if !raised.include?('.')
        data[:dollarsraised] = StatusValue.new(:dollarsraised, raised, goals[:dollarsraised])
      end

      #section[0][0].scan(/<strong>([0123456789.$,]+)<\/strong>&nbsp;([^.]+)/) { |match|
      #  key = match[1].downcase.delete(" ").to_sym
      #  key = :dollarsraised if key == :raised
      #  data[key] = StatusValue.new(key, match[0], goals[key])
      #}

      data
    end

end
