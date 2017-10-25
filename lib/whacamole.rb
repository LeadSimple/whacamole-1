require 'whacamole/config'
require 'whacamole/events'
require 'whacamole/heroku_wrapper'
require 'whacamole/stream'

module Whacamole

  @@config = []

  # Note: accepts multiple configs for the same app_name
  # It is up to you to ensure that they don't overlap or conflict
  def self.configure(app_name)
    @@config << Config.new(app_name)
    yield @@config.last
  end

  def self.monitor
    threads = []
    @@config.each do |config|
      threads << Thread.new do
        heroku = HerokuWrapper.new(config.app_name, config.api_token, config.dynos, config.restart_window)

        while true
          stream_url = heroku.create_log_session
          Stream.new(stream_url, heroku, config.restart_threshold, &config.event_handler).watch
        end
      end
    end
    threads.collect(&:join)
  end
end
