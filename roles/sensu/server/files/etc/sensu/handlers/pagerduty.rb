#!/usr/bin/env ruby
#
# This handler creates and resolves PagerDuty incidents, refreshing
# stale incident details every 30 minutes
#
# Copyright 2011 Sonian, Inc <chefs@sonian.net>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-handler'
require 'redphone/pagerduty'

class Pagerduty < Sensu::Handler

  def incident_key
    @event['client']['name'] + '/' + @event['check']['name']
  end

  def service_owners
    settings['pagerduty']['api_keys']
  end

  def handle
    description = @event['notification'] || [@event['client']['name'], @event['check']['name'], @event['check']['output']].join(' : ')
    service_key = @event['check']['service_owner'] ? service_owners[@event['check']['service_owner']] : settings['pagerduty']['api_key_default']
    begin
      timeout(3) do
        response = case @event['action']
                   when 'create'
                     Redphone::Pagerduty.trigger_incident(
                                                          :service_key => service_key,
                                                          :incident_key => incident_key,
                                                          :description => description,
                                                          :details => @event
                                                          )
                   when 'resolve'
                     Redphone::Pagerduty.resolve_incident(
                                                          :service_key => service_key,
                                                          :incident_key => incident_key
                                                          )
                   end
        if response['status'] == 'success'
          puts 'pagerduty -- ' + @event['action'].capitalize + 'd incident -- ' + incident_key
        else
          puts 'pagerduty -- failed to ' + @event['action'] + ' incident -- ' + incident_key
        end
      end
    rescue Timeout::Error
      puts 'pagerduty -- timed out while attempting to ' + @event['action'] + ' a incident -- ' + incident_key
    end
  end

end
