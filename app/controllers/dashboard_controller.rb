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
    @valueKeys.each { |key|
      if @relayStats.first[key].kind_of?(StatusValue)
        @totals[key] = StatusValue.sum( @relayStats.map {|stat| stat[key]})
      end
    }
  end

  private
    def fetchPage(relay)
      data = { :relay => relay }
      goals = relay.goals

      uri = URI.parse(relay.url)
      req = Net::HTTP.new(uri.host, uri.port)
      req.read_timeout = 60
      res = req.start() { |http|
        http.get(uri.request_uri)
      }

      body = res.body
      if body.nil?
        return data
      end


      section = body.scan(/<div id=.greetingFundProgStats.>\n(.*)\n/);
      section[0][0].scan(/<strong>([0123456789.$,]+)<\/strong>&nbsp;([^.]+)/) { |match|
        key = match[1].downcase.delete(" ").to_sym
        key = :dollarsraised if key == :raised
        data[key] = StatusValue.new(key, match[0], goals[key])
      }

      return data
    end

end
