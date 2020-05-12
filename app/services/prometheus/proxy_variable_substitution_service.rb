# frozen_string_literal: true

module Prometheus
  class ProxyVariableSubstitutionService < BaseService
    include Stepable

    VARIABLE_INTERPOLATION_REGEX = /
      {{                  # Variable needs to be wrapped in these chars.
        \s*               # Allow whitespace before and after the variable name.
          (?<variable>    # Named capture.
            \w+           # Match one or more word characters.
          )
        \s*
      }}
    /x.freeze

    steps :validate_variables,
      :add_params_to_result,
      :substitute_params,
      :substitute_ruby_variables,
      :substitute_liquid_variables

    def initialize(environment, params = {})
      @environment, @params = environment, params.deep_dup
    end

    def execute
      execute_steps
    end

    private

    def validate_variables(_result)
      return success unless variables

      unless variables.is_a?(Array) && variables.size.even?
        return error(_('Optional parameter "variables" must be an array of keys and values. Ex: [key1, value1, key2, value2]'))
      end

      success
    end

    def add_params_to_result(result)
      result[:params] = params

      success(result)
    end

    def substitute_params(result)
      start_time = result[:params][:start_time]
      end_time = result[:params][:end_time]

      result[:params][:start] = start_time if start_time
      result[:params][:end]   = end_time if end_time

      success(result)
    end

    def substitute_liquid_variables(result)
      return success(result) unless query(result)

      result[:params][:query] = gsub(query(result), full_context)

      success(result)
    end

    def substitute_ruby_variables(result)
      return success(result) unless query(result)

      # The % operator doesn't replace variables if the hash contains string
      # keys.
      result[:params][:query] = query(result) % predefined_context.symbolize_keys

      success(result)
    rescue TypeError, ArgumentError => exception
      log_error(exception.message)
      Gitlab::ErrorTracking.track_exception(exception, {
        template_string: query(result),
        variables: predefined_context
      })

      error(_('Malformed string'))
    end

    def gsub(string, context)
      # Search for variables of the form `{{variable}}` in the string and replace
      # them with their value.
      string.gsub(VARIABLE_INTERPOLATION_REGEX) do |match|
        # Replace with the value of the variable, or if there is no such variable,
        # replace the invalid variable with itself. So,
        # `up{instance="{{invalid_variable}}"}` will remain
        # `up{instance="{{invalid_variable}}"}` after substitution.
        context.fetch($~[:variable], match)
      end
    end

    def predefined_context
      @predefined_context ||= Gitlab::Prometheus::QueryVariables.call(@environment)
    end

    def full_context
      @full_context ||= predefined_context.stringify_keys.reverse_merge(variables_hash)
    end

    def variables
      params[:variables]
    end

    def variables_hash
      # .each_slice(2) converts ['key1', 'value1', 'key2', 'value2'] into
      # [['key1', 'value1'], ['key2', 'value2']] which is then converted into
      # a hash by to_h: {'key1' => 'value1', 'key2' => 'value2'}
      # to_h will raise an ArgumentError if the number of elements in the original
      # array is not even.
      variables&.each_slice(2).to_h
    end

    def query(result)
      result[:params][:query]
    end
  end
end
