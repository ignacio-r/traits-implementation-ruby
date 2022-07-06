# frozen_string_literal: true

trait Atacante do
  def ataque
    10
  end
end

trait Defensor do
  def defensa
    50
  end
end

trait Recuperable do
  def recuperarse
    5
  end
end

trait AtacanteRecuperable do
  def ataque
    10
  end

  def recuperarse
    5
  end
end

trait DefensorRecuperable do
  def defensa
    50
  end

  def recuperarse
    7
  end
end

trait Golondrina do
  def especie
    'golondrina'
  end

  def energia
    45
  end

  def volar
    'volar'
  end
end

trait AtacanteMutiplicado do
  def ataque(number)
    10 * number
  end
end
trait AtacanteSumado do
  def ataque(number)
    10 + number
  end
end

trait AtacanteRecuperableMultiplicado do
  def ataque(number)
    10 * number
  end

  def recuperarse(number = 1)
    5 * number
  end
end
trait AtacanteRecuperableSumado do
  def ataque(number)
    10 + number
  end

  def recuperarse(number = 0)
    5 + number
  end
end

trait T1 do
  def count!(num)
    @count = num
  end

  def count
    @count
  end
end

trait T2 do
  def count!(num)
    @count += num
  end
end
