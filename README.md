# Traits 

Implementation proposal in Ruby for OOP 3.

enunciado : https://docs.google.com/document/d/1WyhPsAJtfY2o5YD2L0lHbVM1-hIcsqgmWPCngkrOEQc/edit

Declaration Example:

```ruby
trait Attacker do
    def atack
        10
    end
end 
```


Use Example:

```ruby
class Ghost
    uses Attacker
   
    def name(suffix)
        "Casper" + suffix
    end
end
```


