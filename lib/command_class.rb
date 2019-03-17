class CommandClass

  module Include
    def command_class(dependencies:, inputs:, &blk)
      CommandClass.commandify(self, dependencies, inputs, &blk)
    end
  end

  def self.new(dependencies:, inputs:, &blk)
    commandify(Class.new, dependencies, inputs, &blk)
  end

  # Turns the class into a command class
  #
  def self.commandify(cmd_cls, dependencies, inputs, &blk)
    cmd_cls.const_set('DEFAULT_DEPS', dependencies)

    cmd_cls.class_eval <<~RUBY
      def initialize(**passed_deps)
        deps = DEFAULT_DEPS.merge(passed_deps)
        deps.each { |name, val| instance_variable_set('@' + name.to_s, val) }
      end

      def call(#{cmd_call_signature(inputs)})
        Call.new(#{call_ctor_args(dependencies, inputs)}).()
      end
    RUBY

    call_class = Class.new(cmd_cls, &blk)
    call_class.class_eval <<~RUBY
      def initialize(#{call_ctor_sig(dependencies, inputs)})
        #{set_input_attrs(dependencies, inputs)}
      end
    RUBY

    cmd_cls.const_set('Call', call_class)
    cmd_cls
  end

  class << self

    private


    # TODO: allow for unnamed as well
    def cmd_call_signature(inputs)
      inputs.map {|x| "#{x}:" }.join(', ')
    end

    def set_input_attrs(deps, inputs)
      all_args(deps, inputs).map {|x| "@#{x} = #{x}" }.join('; ')
    end

    def call_ctor_sig(deps, inputs)
      all_args(deps, inputs).join(', ')
    end

    def call_ctor_args(deps, inputs)
      [deps.keys.map { |x| "@#{x}" } + inputs].join(', ')
    end

    def all_args(deps, inputs)
      deps.keys + inputs
    end
  end
end
