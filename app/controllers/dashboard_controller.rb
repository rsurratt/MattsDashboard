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
      res = Net::HTTP.start(uri.host, uri.port) { |http|
        http.get(uri.request_uri)
      }

      body = res.body
      if body.nil?
        return data
      end

      body.scan(/<span id=.rotating_progress\d+.>\n([^:]+): &nbsp;([^\n]+)/) { |match|
        key = match[0].downcase.delete(" ").to_sym
        data[key] = StatusValue.new(key, match[1], goals[key])
      }

      return data
    end

end
