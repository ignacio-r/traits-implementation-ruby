# frozen_string_literal: true

# Strategy abstract class
class Strategy
  def initialize
    @mod = Module.new
  end

  def resolve
    raise NotImplementedError
  end

  def proc_to_method(name, &proc)
    @mod.define_method(name, proc)
    @mod.instance_method name
  end
end

# NoStrategy
class NoStrat < Strategy
  def resolve(dups)
    raise UnresolvedConflictError unless dups.empty?
  end
end

# Arbitrary
class Arbitrary < Strategy
  # No elige un metodo random sino el primero por simplicidad.
  def resolve(dups)
    dups[0]
  end
end

# Sequential
class Sequential < Strategy
  def resolve(dups)
    dups.each_with_index do |method, index|
      if index.even?
        @mod.define_method(method[0], &execute_in_order(method, dups[index + 1]))
      end
    end
    (@mod.instance_methods false).map { |meth| [meth, @mod.instance_method(meth)] }[0]
  end

  def execute_in_order(method, next_method)
    proc { |*params, &block|
      method[1].bind(self).call(*params, &block)
      next_method[1].bind(self).call(*params, &block)
    }
  end
end

# Conditional
class Conditional < Strategy
  UNSATISFIED_CONDITION = "Ninguno cumple la condicion"

  def initialize(&cond)
    super()
    @function = cond

  end

  def resolve(dups)
    [dups[0][0], conditionalize(dups)]
  end

  def conditionalize(dups)
    function = @function
    error_message = UNSATISFIED_CONDITION
    proc_to_method(dups[0][0], &proc { |*params, &proc|
      method = dups.find {|tuple| function.call(tuple[1].bind(self).call(*params,&proc))}
      if method.nil?
        raise StandardError.new error_message
      end
      method[1].bind(self).call(*params, &proc)
    })
  end
end

# InjectStrategy
class InjectStrategy < Strategy
  def initialize(&block)
    super()
    @function = block
  end

  def resolve(dups)
    dups.each_with_index do |method, index|
      if index.even?
        @mod.define_method(method[0], &create_wrapper(method, dups[index + 1]))
      end
    end
    # funciona porque siempre le va a llegar un par de duplicados
    [name = dups[0][0], @mod.instance_method(name)]
  end

  def create_wrapper(method_a, method_b)
    function = @function
    proc { |*params, &block|
      method_a_res = method_a[1].bind(self).call(*params, &block)
      method_b_res = method_b[1].bind(self).call(*params, &block)
      function.call(method_a_res, method_b_res)
    }
  end
end

# Custom strategy example of extension
class FiboStrat < Strategy
  def resolve(dups)
    methods_and_values = []
    dups.each_with_index do |tuple_method, _index|
      val = tuple_method[1].bind(@mod).call
      methods_and_values << [tuple_method[1], fibonacci(val)]
    end
    method_name = dups[0][0]
    selected_method = max_fib(methods_and_values)
    [method_name, selected_method]
  end

  def fibonacci(num)
    return num if (0..1).include? num

    (fibonacci(num - 1) + fibonacci(num - 2))
  end

  def max_fib(methods_and_values)
    methods_and_values.max do |first_fib_tuple, second_fib_tuple|
      first_fib_tuple[1] <=> second_fib_tuple[1]
    end[0]
  end
end
