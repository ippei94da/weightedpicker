#! /usr/bin/env ruby
# coding: utf-8

#
#
#
class WeightedPicker::Tree
  #
  def initialize(data)
    @size = data.size #for return hash.

    @names = data.keys
    @weights = []
    @weights[0] = data.values

    @size.upto ((2 ** depth) - 1) do |i|
      weights[i] = 0
    end

    depth.times do |i|
      tmp = []
      (@weights[i].size / 2).times do |j|
        tmp << @weights[i][2*j] + @weights[i][2*j + 1]
      end
      @weights << tmp
    end

    @weights.reverse!
  end

  # Return internal data as a Hash.
  def names_weights
    results = {}
    @size.times do |i|
      results[@names] = @weights[-1]
    end
    results
  end

  #If nums is false or nil, use random.
  def pick(nums = false)
    current_index = 0
    depth.times do |i|
      next_id0 = 2 * current_index
      next_id1 = 2 * current_index + 1
      choise = choose( @weights[i+1][next_id0], @weights[i+1][next_id1], nums.shift)
      current_index = 2 * current_index + choise
    end
    return @names[current_index]

    #raise NoEntryError if @weights.empty?

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
    #raise NotExistKeyError unless @weights.has_key?(item)
    #@weights[ item ] *= 2
    #@weights[ item ] = MAX_WEIGHT if MAX_WEIGHT < @weights[ item ]
    id = index(item)
    weight = @weights[-1][id]
    half = weight / 2
    add_ancestors(id, half)
  end

  def lighten(item)
    id = index(item)
    weight = @weights[-1][id]
    half = weight / 2
    add_ancestors(id,  - half)
    #raise NotExistKeyError unless @weights.has_key?(item)
    ##@weights.each do |key, val|
    ##  weigh(key) unless key == item
    ##end
    #if @weights[ item ] == 0
    #  #@weights[ item ] = 0
    #elsif @weights[ item ] == MIN_WEIGHT
    #  @weights[ item ] = MIN_WEIGHT
    #else
    #  @weights[ item ] /= 2
    #end
  end

  private

  def add_ancestors(id, val)
    depth.times do |d|
      size = 2 ** d
      x = region(size, id)
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

  def choose(num0, num1, random = nil)
    sum = num0 + num1
    random ||= rand(sum) 

    return if num0 < random
  end

  def index(item)
    return @names.find(item)
    #raise WeightedPicker::Tree::NoEntryError
  end

end

