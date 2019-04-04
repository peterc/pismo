module Pismo
  module Utils
    class LogTracker
      def increment(key, increment = 1)
        Pismo.logger.info "TRACK INCREMENT #{key} #{increment}" if send_log?
      end

      def count(key, increment = 1)
        Pismo.logger.info "TRACK COUNT #{key} #{increment}" if send_log?
      end

      def decrement(key, decrement = 1)
        Pismo.logger.info "TRACK DECREMENT #{key} #{decrement}" if send_log?
      end

      def timing(key, val)
        Pismo.logger.info "TRACK TIMING #{key} #{val}" if send_log?
      end

      def gauge(key, val)
        Pismo.logger.info "TRACK GAUGE #{key} #{val}" if send_log?
      end

      def time(key)
        track_time_start = Time.now
        yield if block_given?
        delta_time = Time.now - track_time_start
        Pismo.logger.info "TRACK TIME #{key} #{delta_time}" if send_log?
      end

      def send_log?
        @send_log ||= [true, 'true'].include?(ENV.fetch('PISMO_STATS_LOGGING', true))
      end
    end
  end
end
