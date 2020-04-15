# frozen_string_literal: true

require 'prometheus/pid_provider'

module Gitlab
  module Utils
    class Measuring

      class << self
        def execute_with(measurement_enabled, logger, base_data)
          measurement_enabled ? measuring(logger, base_data).with_measuring { yield } : yield
        end

        private

        def measuring(logger, base_data)
          Gitlab::Utils::Measuring.new(logger: logger, base_data: base_data)
        end
      end

      def initialize(logger: nil, base_data: {})
        @logger = logger || Logger.new($stdout)
        @base_data = base_data
      end

      def with_measuring
        result = with_gc_stats do
          with_count_queries do
            with_measure_time do
              yield
            end
          end
        end

        log_info(
          gc_stats: @gc_stats,
          time_to_finish: @time_to_finish,
          number_of_sql_calls: @count,
          memory_usage: "#{Gitlab::Metrics::System.memory_usage.to_f / 1024 / 1024} MiB",
          label: ::Prometheus::PidProvider.worker_id
        )

        result
      end

      private

      attr_reader :logger, :base_data

      def with_count_queries(&block)
        @count = 0

        counter_f = ->(_name, _started, _finished, _unique_id, payload) {
          @count += 1 unless payload[:name].in? %w[CACHE SCHEMA]
        }

        ActiveSupport::Notifications.subscribed(counter_f, "sql.active_record", &block)
      end

      def log_info(details)
        details = base_data.merge(details)
        details = details.to_yaml if ActiveSupport::Logger.logger_outputs_to?(logger, STDOUT)
        logger.info(details)
      end

      def with_gc_stats
        GC.start # perform a full mark-and-sweep
        stats_before = GC.stat
        result = yield
        stats_after = GC.stat
        @gc_stats = stats_after.map do |key, after_value|
          before_value = stats_before[key]
          [key, before: before_value, after: after_value, diff: after_value - before_value]
        end.to_h
        result
      end

      def with_measure_time
        result = 0
        @time_to_finish = Benchmark.realtime do
          result = yield
        end

        result
      end

      def duration_in_numbers(duration_in_seconds)
        milliseconds = duration_in_seconds.in_milliseconds % 1.second.in_milliseconds
        seconds = duration_in_seconds % 1.minute
        minutes = (duration_in_seconds / 1.minute) % (1.hour / 1.minute)
        hours = duration_in_seconds / 1.hour

        if hours == 0
          "%02d:%02d:%03d" % [minutes, seconds, milliseconds]
        else
          "%02d:%02d:%02d:%03d" % [hours, minutes, seconds, milliseconds]
        end
      end
    end
  end
end
