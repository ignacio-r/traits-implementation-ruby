# frozen_string_literal: true

require_relative 'strategies.rb'

# Trait
class Trait
  attr_accessor :provided_methods

  def self.unprovided_error(name)
    "Unprovided method: #{name}"
  end

  def self.symbol_error(object)
    "Expected a symbol but got: #{object}"
  end

  def initialize(methods: {})
    @provided_methods = methods
  end

  def eval_for(a_class)
    @provided_methods.each do |method_name, method|
      next if a_class.instance_methods.include? method_name

      a_class.define_method(method_name, method)
    end
  end

  def +(other, strategy_map = {})
    strategy_map.default = NoStrat.new
    all = @provided_methods.to_a + other.provided_methods.to_a
    dups = collect_dup_methods(all)
    resolved = resolve_all_conflicts(strategy_map, dups)
    clean = all - dups + resolved
    self.class.new methods: clean.to_h
  end

  def <<(name_aliases)
    assert_well_defined? name_aliases
    methods_copy = @provided_methods.clone
    name_aliases.each do |old_name, new_name|
      methods_copy[new_name] = methods_copy[old_name]
    end
    self.class.new methods: methods_copy
  end

  def -(*method_names)
    assert_symbols(method_names)
    new_names = names - method_names.flatten
    new_methods = @provided_methods.select { |method| new_names.include? method }
    self.class.new methods: new_methods
  end

  def names
    @provided_methods.keys
  end

  private

  def resolve_all_conflicts(strategy_map, dups)
    methods_resolved = []
    dups.each do |tuple_method|
      method_name = tuple_method[0]
      conflicting_one = tuple_method
      conflicting_two = find_duplicated(tuple_method, dups)
      unless duplicated_in_methods?(tuple_method, methods_resolved)
        methods_resolved << strategy_map[method_name].resolve([conflicting_one, conflicting_two])
      end
    end
    methods_resolved
  end

  # Prop: recolecta los metodos duplicados
  def collect_dup_methods(methods)
    methods.select { |met| duplicated_in_methods?(met, methods) }
  end

  # Prop: devuelve true si el metodo tiene el mismo nombre y diferente owner que otro en la lista
  def duplicated_in_methods?(method, methods)
    methods.any? do |each_method|
      duplicated?(each_method, method)
    end
  end

  def find_duplicated(method, methods)
    methods.find { |each_method| duplicated?(method, each_method) }
  end

  def duplicated?(method_tuple_one, method_tuple_two)
    method_tuple_two[0] == method_tuple_one[0] && method_tuple_two[1].owner != method_tuple_one[1].owner
  end

  def assert_symbols(method_names)
    method_names.flatten.each { |name| assert_symbol name }
  end

  def assert_well_defined?(method_names)
    method_names.each do |name, an_alias|
      assert_symbol an_alias
      unless names.include?(name)
        raise StandardError, self.class.unprovided_error(name)
      end
    end
  end

  def assert_symbol(object)
    return if object.is_a? Symbol

    raise StandardError, self.class.symbol_error(object)
  end
end

# Global
def trait(const_name, &block)
  mod = Module.new
  mod.module_eval(&block)
  methods_names = mod.instance_methods false
  methods = methods_names.map { |method_name| [method_name, mod.instance_method(method_name)] }
  new_trait = Trait.new methods: methods.to_h
  Object.const_set const_name, new_trait
end

def Object.const_missing(const)
  const
end

# Class
class Class
  def uses(trait)
    trait.eval_for self
    self
  end
end

# UnresolvedConflictError
class UnresolvedConflictError < StandardError


  def initialize
    super(UNRESOLVED_METHOD_CONFLICT)
  end
end
