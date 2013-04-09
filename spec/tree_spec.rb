require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require "stringio"
require "fileutils"

class WeightedPicker::Tree
  public :log2_ceil
  public :depth
  public :choose
  attr_reader :weights
end

describe "Weightedpicker::Tree" do
  before do
    @tree00 = WeightedPicker::Tree.new({"A" => 2, "B" => 1, "C" => 1})
    @tree01 = WeightedPicker::Tree.new({"A" => 0})
  end

  describe "initialize" do
    #@tree00
  end

  describe "names_weights" do
    @tree00.names_weights.should == {"A" => 2, "B" => 1, "C" => 1}
  end

  describe "pick" do
    @tree00.pick([0,0]).should == "A"
    @tree00.pick([0,1]).should == "A"
    @tree00.pick([0,2]).should == "B"
    @tree00.pick([1,0]).should == "A"
    @tree00.pick([1,1]).should == "A"
    @tree00.pick([1,2]).should == "B"
    @tree00.pick([2,0]).should == "A"
    @tree00.pick([2,1]).should == "A"
    @tree00.pick([2,2]).should == "B"
    @tree00.pick([3,0]).should == "C"
    @tree00.pick([3,1]).should == "C"
    @tree00.pick([3,2]).should == "C"

    lambda{ @tree01.pick}.should raise_error(WeightedPicker::Tree::NoEntryError)
  end

  describe "weigh" do
    @tree00.weigh "A"
    @tree00.names_weights.should == {"A" => 4, "B" => 1, "C" => 1}
    @tree00.weights.should == [
      [6],
      [5,1],
      [4,1,1,0],
    ]
    lambda{ @tree00.weigh("C")}.should raise_error(WeightedPicker::Tree::NoEntryError)
  end

  describe "lighten" do
    @tree00.lighten "A"
    @tree00.names_weights.should == {"A" => 1, "B" => 1, "C" => 1}
    @tree00.weights.should == [
      [3],
      [2,1],
      [1,1,1,0],
    ]
    lambda{ @tree00.lighten("C")}.should raise_error(WeightedPicker::Tree::NoEntryError)
  end

  describe "log2_ceil" do
    lambda{ @tree00.log2(0)}.should raise_error(WeightedPicker::Tree::NoEntryError)
    @tree00.log2_ceil( 1).should == 0
    @tree00.log2_ceil( 2).should == 1
    @tree00.log2_ceil( 3).should == 2
    @tree00.log2_ceil( 4).should == 2
    @tree00.log2_ceil( 8).should == 3
    @tree00.log2_ceil(16).should == 4
    @tree00.log2_ceil(20).should == 5
  end

  describe "choose" do
    @tree00.choose(1,2,0).should == 0
    @tree00.choose(1,2,1).should == 1
    @tree00.choose(1,2,2).should == 1
  end

  describe "find" do
    @tree00.find("A").should == 0
    @tree00.find("B").should == 1
    #lambda{ @tree00.find("C")}.should raise_error(WeightedPicker::Tree::NoEntryError)
  end

end

