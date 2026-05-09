# ==============================================================================
# RAB Pro - Logger Utility
# Simple logging system with DEBUG, INFO, WARN, ERROR levels
# ==============================================================================

module RABPro
  class Logger
    DEBUG = 0
    INFO  = 1
    WARN  = 2
    ERROR = 3

    @@level = INFO
    @@messages = []
    @@max_messages = 1000

    def self.level=(val)
      @@level = val
    end

    def self.debug(msg)
      _log(DEBUG, '[DEBUG]', msg) if @@level <= DEBUG
    end

    def self.info(msg)
      _log(INFO, '[INFO]', msg) if @@level <= INFO
    end

    def self.warn(msg)
      _log(WARN, '[WARN]', msg) if @@level <= WARN
    end

    def self.error(msg)
      _log(ERROR, '[ERROR]', msg) if @@level <= ERROR
    end

    def self.messages
      @@messages
    end

    def self.clear_messages
      @@messages = []
    end

    private

    def self._log(level, prefix, msg)
      timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
      formatted = "#{timestamp} #{prefix} #{msg}"
      
      # Store in memory
      @@messages << formatted
      if @@messages.size > @@max_messages
        @@messages.shift
      end
      
      # Output to console
      puts formatted
    end
  end
end
