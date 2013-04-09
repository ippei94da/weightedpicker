#! /usr/bin/env ruby
# coding: utf-8

#
#
#
class WeightedPicker::Tree
  #
  def initialize(hash)
    @size = hash.size #for return hash.

    @names = hash.keys
    @weights = []
    @weights[0] = hash.values

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
  def hash
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
    @weights[-1][current_index]

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
    index = find(item)
    depth.times do |i|
      @weights[i]
    end
  end

  def lighten(item)
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

  def find(item)
    return @names.find(item)
    #raise WeightedPicker::Tree::NoEntryError
  end

end

