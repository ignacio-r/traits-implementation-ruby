# frozen_string_literal: true

require 'rspec'
require_relative '../lib/trait'
require_relative './auxiliares/traits'

require_relative '../lib/strategies'

describe Trait do
  it 'una clase usa un trait que tiene un metodo' do
    guerrero = instance_uses Atacante

    expect(guerrero.ataque).to eq(10)
  end

  it 'cuando una clase que define un metodo y usa un trait que implementa ese mensaje,
      entonces se le da prioridad al metodo de la clase' do
    fantasma = fantasma_uses Atacante

    expect(fantasma.ataque).to eq(20)
  end

  it 'una clase usa un trait compuesto por dos traits diferentes y responde sus mensajes' do
    trait = Atacante + Defensor
    guerrero = instance_uses trait

    expect(guerrero.ataque).to eq(10)
    expect(guerrero.defensa).to eq(50)
  end

  it 'cuando una clase usa un trait compuesto con ese mismo trait entonces lo usa como si no fuera compuesto' do
    trait = Atacante + Atacante
    guerrero = instance_uses trait

    expect(guerrero.ataque).to eq(10)
  end

  it 'componer dos traits compuestos por un mismo trait no genera conflictos' do
    atacante = Atacante + Recuperable
    defensor = Defensor + Recuperable

    guerrero = instance_uses(atacante + defensor)

    expect(guerrero.recuperarse).to eq(5)
  end

  it 'componer dos traits con un metodo con el mismo nombre levanta una excepción' do
    expect { AtacanteRecuperable + DefensorRecuperable }
      .to raise_error(UnresolvedConflictError)
  end

  it 'cuando una clase usa un trait que excluye uno de sus metodos entonces
      genera un error de metodo no definido' do
    trait = (Atacante - :ataque)
    guerrero = instance_uses trait

    expect { guerrero.ataque }.to raise_error NoMethodError
  end

  it 'cuando una clase usa un trait compuesto mediante una exclusion que evita un conflicto,
      entonces usa el metodo del otro trait' do
    trait = AtacanteRecuperable + (DefensorRecuperable - :recuperarse)
    guerrero = instance_uses trait

    expect(guerrero.recuperarse).to eq(5)
  end

  it 'una clase usa un trait que excluye los metodos con una lista de sus nombres' do
    method_names = %i[volar especie]
    pepita = instance_uses Golondrina - method_names

    expect { pepita.volar }.to raise_error NoMethodError
    expect { pepita.especie }.to raise_error NoMethodError
    expect(pepita.energia).to eq(45)
  end

  it 'una clase usa un trait que excluye los metodos utilizando multiples veces la exclusion' do
    pepita = instance_uses(Golondrina - :volar - :especie)

    expect { pepita.volar }.to raise_error NoMethodError
    expect { pepita.especie }.to raise_error NoMethodError
    expect(pepita.energia).to eq(45)
  end

  it 'cuando un trait excluye algo que no es un simbolo lanza un error' do
    trait = Golondrina
    wrong_name = 3
    expect { trait - :energia - wrong_name }.to raise_error(StandardError, Trait.symbol_error(wrong_name))
  end

  it 'una clase usa un trait y a ese trait se le define un alias con esa operacion, sin perder el primer mensaje' do
    guerrero = instance_uses(Atacante << { ataque: :mortal_invertida })
    expect(guerrero.mortal_invertida).to eq(10)
    expect(guerrero.ataque).to eq(10)
  end

  it 'cuando un trait no provee un metodo para realizar un alias de nombres lanza un error' do
    trait = Defensor
    name_aliases = { m1: :m2 }
    expect { trait << name_aliases }.to raise_error(StandardError, Trait.unprovided_error(:m1))
  end

  it 'cuando un trait recibe un alias que no es un simbolo lanza un error' do
    trait = Defensor
    wrong_alias = 1
    name_aliases = { m1: wrong_alias }
    expect { trait << name_aliases }.to raise_error(StandardError, Trait.symbol_error(wrong_alias))
  end

  it 'cuando una clase usa la estrategia inyectable para metodos conflictivos sin parametros,
      entonces retorna lo que la funcion decida' do
    function = proc { |value_a, value_b| value_a + value_b }
    strategy = injectable function
    atac_recuperable = instance_uses AtacanteRecuperable
    def_recuperable = instance_uses DefensorRecuperable

    expected = function.call(atac_recuperable.recuperarse, def_recuperable.recuperarse)

    trait_result = AtacanteRecuperable.+(DefensorRecuperable, { recuperarse: strategy })

    strategy_resolved = instance_uses trait_result
    expect(strategy_resolved.recuperarse).to eq(expected)
  end

  it 'cuando una clase usa la estrategia inyectable para metodos conflictivos con parametros, entonces retorna lo que la funcion decida' do
    function = proc { |value_a, value_b| value_a + value_b }
    strategy = injectable function
    atac_mul = instance_uses AtacanteMutiplicado
    atac_sum = instance_uses AtacanteSumado
    expected = function.call(atac_mul.ataque(5), atac_sum.ataque(5))

    trait_result = AtacanteMutiplicado.+(AtacanteSumado, { ataque: strategy })

    strategy_resolved = instance_uses trait_result
    expect(strategy_resolved.ataque(5)).to eq(expected)
  end

  it 'una clase usa dos traits con un metodo conflictivo y adopta la estrategia arbitraria para resolverlo' do
    guerrero = instance_uses(Recuperable.+(DefensorRecuperable, { recuperarse: arbitrary }))

    expect(guerrero.recuperarse).to eq(5)
  end

  it 'cuando una clase usa dos traits con un metodo conflictivo y adopta la estrategia secuencial,
      entonces los ejecuta en orden' do
    trait_result = T1.+(T2, { count!: Sequential.new })

    strategy_resolved = instance_uses trait_result
    strategy_resolved.count!(10)

    expect(strategy_resolved.count).to eq(20)
  end

  it 'cuando una clase usa dos traits con un metodo conflictivo y adopta la estrategia arbitraria,
      entonces elige el primero de los dos' do
    guerrero = instance_uses(Recuperable.+(DefensorRecuperable, { recuperarse: arbitrary }))

    expect(guerrero.recuperarse).to eq(5)
  end

  it 'cuando hay multiples metodos coflictivos estos se resuelven con una estrategia para cada uno' do
    function = proc { |value_a, value_b| value_a + value_b }
    resolutions = { ataque: injectable(function), recuperarse: arbitrary }
    guerrero = instance_uses(AtacanteRecuperableMultiplicado.+(AtacanteRecuperableSumado, resolutions))

    expect(guerrero.recuperarse(3)).to eq(15)
  end

  it 'al componer un trait con otro se resuelven los conflictos del metodo con una estrategia custom' do
    strategy = FiboStrat.new
    guerrero = instance_uses(Recuperable.+(DefensorRecuperable, { recuperarse: strategy }))

    expect(guerrero.recuperarse).to eq(7)
  end

  it 'al componer un trait con otro se resuelven los conflictos del metodo con la estrategia condicional' do
    strategy = Conditional.new { |value| value > 5 }
    guerrero = instance_uses(Recuperable.+(DefensorRecuperable, { recuperarse: strategy }))

    expect(guerrero.recuperarse).to eq(7)
  end

  it 'al componer un trait con otro se resuelven los conflictos del metodo con la estrategia condicional
      y ninguno cumple la condicion' do
    strategy = Conditional.new { |value| value > 8 }
    guerrero = instance_uses(Recuperable.+(DefensorRecuperable, { recuperarse: strategy }))

    expect { guerrero.recuperarse }.to raise_error(StandardError, Conditional::UNSATISFIED_CONDITION)
  end

  it 'al componer un trait con otro se resuelven los conflictos del metodo con parametron, usando la estrategia condicional' do
    strategy = Conditional.new { |value| value > 15 }
    guerrero = instance_uses(AtacanteSumado.+(AtacanteMutiplicado, { ataque: strategy }))

    expect(guerrero.ataque(5)).to eq(50)
  end
end

def fantasma_uses(trait)
  a_class = Class.new
  a_class.define_method(:ataque) { 20 }
  a_class.uses(trait).new
end

def instance_uses(trait)
  Class.new.uses(trait).new
end

def injectable(function)
  InjectStrategy.new(&function)
end

def arbitrary
  Arbitrary.new
end
