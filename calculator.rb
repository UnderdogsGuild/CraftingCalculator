require 'bundler/setup'
require 'active_support/all'

class Item < Struct.new(:name, :requirements)
end

class Requirement < Struct.new(:name, :count)
end

ITEMS = [
  Item.new("16384k ME Storage Component", [Requirement.new("4096k ME Storage Component", 3), Requirement.new("Engineering Processor", 1), Requirement.new("Glowstone Dust", 4), Requirement.new("Logic Processor", 1)]),
  Item.new("4096k ME Storage Component", [Requirement.new("1024k ME Storage Component", 3), Requirement.new("Engineering Processor", 1), Requirement.new("Glowstone Dust", 4), Requirement.new("Logic Processor", 1)]),
  Item.new("1024k ME Storage Component", [Requirement.new("256k ME Storage Component", 3), Requirement.new("Engineering Processor", 1), Requirement.new("Glowstone Dust", 4), Requirement.new("Logic Processor", 1)]),
  Item.new("256k ME Storage Component", [Requirement.new("64k ME Storage Component", 3), Requirement.new("Engineering Processor", 1), Requirement.new("Glowstone Dust", 4), Requirement.new("Logic Processor", 1)]),
  Item.new("64k ME Storage Component", [Requirement.new("16k ME Storage Component", 3), Requirement.new("Quartz Glass", 1), Requirement.new("Glowstone Dust", 4), Requirement.new("Calculation Processor", 1)]),
  Item.new("16k ME Storage Component", [Requirement.new("4k ME Storage Component", 3), Requirement.new("Quartz Glass", 1), Requirement.new("Glowstone Dust", 4), Requirement.new("Calculation Processor", 1)]),
  Item.new("4k ME Storage Component", [Requirement.new("1k ME Storage Component", 3), Requirement.new("Quartz Glass", 1), Requirement.new("Glowstone Dust", 4), Requirement.new("Calculation Processor", 1)]),
  Item.new("1k ME Storage Component", [Requirement.new("Fluix Crystal", 4), Requirement.new("Logic Processor", 1), Requirement.new("Redstone", 4)]),
  Item.new("Engineering Processor", [Requirement.new("Printed Engineering Circuit", 1), Requirement.new("Printed Silicon", 1), Requirement.new("Redstone", 1)]),
  Item.new("Printed Engineering Circuit", [Requirement.new("Diamond", 1)]),
  Item.new("Logic Processor", [Requirement.new("Printed Logic Circuit", 1), Requirement.new("Printed Silicon", 1), Requirement.new("Redstone", 1)]),
  Item.new("Printed Silicon", [Requirement.new("Silicon", 1)]),
  Item.new("Printed Logic Circuit", [Requirement.new("Gold Ingot", 1)]),
  Item.new("Quartz Glass", [Requirement.new("Crushed Quartz", 4.0/5.0), Requirement.new("Glass", 1)]),
  Item.new("Crushed Quartz", [Requirement.new("Nether Quartz", 1)]),
  Item.new("Calculation Processor", [Requirement.new("Printed Calculation Circuit", 1), Requirement.new("Printed Silicon", 1), Requirement.new("Redstone", 1)]),
  Item.new("Printed Calculation Circuit", [Requirement.new("Pure Nether Quartz Crystal", 1)]),
  Item.new("Pure Nether Quartz Crystal", [Requirement.new("Nether Quartz Seed", 1)]),
  Item.new("Nether Quartz Seed", [Requirement.new("Crushed Quartz", 0.5), Requirement.new("Sand", 0.5)]),
  Item.new("Fluix Crystal", [Requirement.new("Crystalized Menril Chunk", 1), Requirement.new("Redstone", 1)]),
  Item.new("Glowstone Dust", [Requirement.new("Glowstone", 0.25)]),
  Item.new("Silicon", [Requirement.new("Crushed Quartz", 1)]),
  Item.new("Glass", [Requirement.new("Sand", 1)])
]

ITEMS_IN_STORAGE = {
    "Diamond" => 0,
    "Crystalized Menril Chunk" => 0,
    "Glowstone Dust" => 64*69+56,
    "Redstone" => 64*216+30,
    "Nether Quartz" => 20,
    "Crushed Quartz" => 64*14+22,
    "Fluix Crystal" => 64*144+56,
    "Printed Logic Circuit" => 64*33+63,
    "Printed Engineering Circuit" => 64*11+49,
    "Printed Silicon" => 64*55+24,
    "Silicon" => 0,
    "1k ME Storage Component" => 64*1+3,
    "Gold Ingot" => 0,
    "Sand" => 64*10+5,
    "Glass" => 64*16+29,
    "Pure Nether Quartz Crystal" => 64*19,
    "Nether Quartz Seed" => 0
}

class Calculator
  def initialize(target_requirements, items)
    @target_requirements = Array(target_requirements)
    @items = items.each_with_object({}) do |item, hash|
      hash[item.name] = item
    end
    @storage = ITEMS_IN_STORAGE.dup
  end

  def calculate_required_raw_materials
    @raw_materials = required_items_hash(@target_requirements)
    @phases = [@raw_materials.dup]
    updated = true
    while updated
      updated = false
      new_items_hash = {}
      @raw_materials.each do |item_name, count|
        if @items.key? item_name
          updated = true
          @raw_materials.delete(item_name)
          @items[item_name].requirements.each do |requirement|
            required_amount = requirement.count * count
            amount_removed = 0
            if storage_has_item? requirement.name
              amount_removed = remove_from_storage(requirement.name, required_amount)
              next if amount_removed == required_amount
            end

            new_items_hash[requirement.name] = if new_items_hash[requirement.name].present?
              new_items_hash[requirement.name] + required_amount - amount_removed
            else
              required_amount - amount_removed
            end
          end
        end
      end

      @phases.prepend new_items_hash if updated

      @raw_materials.merge!(new_items_hash) do |_key, existing, newest|
        existing + newest
      end
    end
  end

  def storage_has_item?(item)
    @storage.key?(item) && @storage[item].positive?
  end

  def remove_from_storage(item, amount)
    if @storage[item] > amount
      @storage[item] = @storage[item] - amount
      amount
    else
      val = @storage[item]
      @storage.delete(item)
      val
    end
  end

  def required_items_hash(requirements)
    requirements.each_with_object({}) do |requirement, hash|
      if storage_has_item? requirement.name
        amount_removed = remove_from_storage(requirement.name, requirement.count)
        next if amount_removed == requirement.count
      end

      hash[requirement.name] = if hash[requirement.name].present?
        hash[requirement.name] + requirement.count - amount_removed
      else
        requirement.count
      end
    end
  end

  def result
    output = "\n"
    output << "Target Requirements:\n"
    @target_requirements.each do |requirement|
      output << "\t#{requirement.name}: #{requirement.count}\n"
    end
    output << "Required Raw Materials:\n"
    @raw_materials.each do |name, count|
      output << "\t#{name}: #{count.to_f.ceil}\n"
    end

    output << "Steps:\n"
    @phases.each_with_index do |phase, index|
      output << "\tStep #{index + 1}:\n"
      phase.each do |name, amount|
        output << "\t\tCraft #{amount.to_f.ceil} #{name.pluralize}\n"
      end
    end

    output
  end
end

calc = Calculator.new([Requirement.new("16384k ME Storage Component", 1)], ITEMS)
calc.calculate_required_raw_materials
puts calc.result