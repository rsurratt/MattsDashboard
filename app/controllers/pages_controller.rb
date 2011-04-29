require 'net/http'
require 'uri'

class PagesController < ApplicationController
  def dashboard
    @relayStats = [
      fetchPage('http://main.acsevents.org/site/TR?pg=entry&fr_id=29348'),
      fetchPage('http://main.acsevents.org/site/TR?pg=entry&fr_id=31135'),
      fetchPage('http://main.acsevents.org/site/TR?pg=entry&fr_id=31206'),
      fetchPage('http://main.acsevents.org/site/TR?pg=entry&fr_id=31102')
    ]
  end

  private
    def fetchPage(url)
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
        data[key] = match[1]
      }

      return data
    end

end
