module Sheen
  class Admin < EventMachine::Connection
    def receive_data(data)
      begin
        data = JSON.parse(data)
      rescue Exception => e
        send_data('Invalid command')
      end
  
      case data['command']
      when 'purge'
        Url.where(:uri => /#{data['argument']}/).each(&:destroy)
      end
    end
  end
end
