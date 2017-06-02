require 'dxopal/remote_resource'

module DXOpal
  class Sound < RemoteResource
    # Return AudioContext
    def self.audio_context
      @@audio_context ||= %x{
        new (window.AudioContext||window.webkitAudioContext)
      }
    end

    # Load remote sound (called via Window.load_resources)
    def self._load(path_or_url)
      snd = new(path_or_url)
      snd_promise = %x{
        new Promise(function(resolve, reject) {
          var request = new XMLHttpRequest();
          request.open('GET', #{path_or_url}, true);
          request.responseType = 'arraybuffer';
          request.onload = function() {
            var audioData = request.response;
            var context = #{Sound.audio_context};
            context.decodeAudioData(audioData, function(decoded) {
              snd['$decoded='](decoded);
              resolve();
            });
          };
          request.send();
        });
      }
      return snd, snd_promise
    end

    def initialize(path_or_url)
      @path_or_url = path_or_url  # Used in error message
    end
    attr_accessor :decoded

    # Play this sound once
    def play
      raise "Sound #{path_or_url} is not loaded yet" unless @decoded
      %x{
        var context = #{Sound.audio_context};
        var source = context.createBufferSource();
        source.buffer = #{@decoded};
        source.connect(context.destination);
        source.start(0); 
      }
    end
  end
end
