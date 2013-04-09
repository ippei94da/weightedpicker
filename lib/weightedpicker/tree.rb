#! /usr/bin/env ruby
# coding: utf-8

#
#
#
class WeightedPicker::Tree

  attr_reader :size

  class NoEntryError < Exception; end

  #
  def initialize(data)
    @size = data.size #for return hash.

    @names = data.keys
    @weights = []
    @weights[0] = data.values

    #Fill 0 to 2**n
    @size.upto ((2 ** depth) - 1) do |i|
      @weights[0][i] = 0
    end

    depth.times do |i|
      @weights[i+1] = []
      num = @weights[i].size
      (num - num / 2).times do |j|
        @weights[i+1] << @weights[i][2*j] + @weights[i][2*j + 1]
      end
    end

    @weights.reverse!
  end

  # Return internal data as a Hash.
  def names_weights
    results = {}
    @size.times do |i|
      results[@names[i]] = @weights[-1][i]
    end
    results
  end

  def pick
    raise NoEntryError if @weights[0][0] == 0

    current_index = 0
    depth.times do |i|
      next_id0 = 2 * current_index
      next_id1 = 2 * current_index + 1
      #puts
      choise = choose( @weights[i+1][next_id0], @weights[i+1][next_id1])
      current_index = 2 * current_index + choise
    end
    return @names[current_index]


    #sums = []
    #keys = []
    #sum = 0
    #@weights.each do |key, weight|
    #  keys << key
    #  sum += weight
    #  sums << sum
    #end

    #num ||= rand(sum)
    ## find index of first excess a number
    #sums.each_with_index do |item, index|
    #  return keys[index] if num < item
    #end
  end

  def weigh(item)
    raise NoEntryError unless @names.include?(item)
    id = index(item)
    weight = @weights[-1][id]
    add_ancestors(id, weight)
  end

  def lighten(item)
    raise NoEntryError unless @names.include?(item)
    id = index(item)
    weight = @weights[-1][id]
    add_ancestors(id,  - weight / 2)
  end

  private

  def add_ancestors(id, val)
    (depth+1).times do |d|
      divisor = 2 ** (depth - d)
      x = id / divisor
      @weights[d][x] += val
    end
  end

  def log2_ceil(num)
    result = 0
    while (num > 1)
      result += 1
      num -= num/2
    end
    result
  end

  def depth
    log2_ceil(@size)
  end

  def choose(num0, num1)
    sum = num0 + num1

    # 0, 1, 2
    return 0 if rand(sum) < num0
    return 1
  end

  def index(item)
    return @names.index(item)
    #raise WeightedPicker::Tree::NoEntryError
  end

end

