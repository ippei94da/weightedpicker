require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require "stringio"
require "fileutils"

class WeightedPicker::Tree
  public :log2_ceil
  public :depth
  public :choose
  public :index
  attr_reader :weights
end

#puts rand(100000)
#puts rand(100000)
#puts rand(100000)
#puts rand(100000)

describe "Weightedpicker::Tree" do
  before do
    @tree00 = WeightedPicker::Tree.new({"A" => 2, "B" => 1, "C" => 1})
    @tree01 = WeightedPicker::Tree.new({"A" => 0})
    @tree02 = WeightedPicker::Tree.new({})
  end

  it "should do in initialize" do
    #@tree00
  end

  it "should return a hash of names_weights" do
    #@tree00 = WeightedPicker::Tree.new({"A" => 2, "B" => 1, "C" => 1})
    @tree00.names_weights.should == {"A" => 2, "B" => 1, "C" => 1}
  end

  it "should pick" do
    results = {"A" => 0, "B" => 0, "C" => 0}
    srand(0)
    300.times do
      results[@tree00.pick] += 1
    end
    #pp results #=> {"A"=>152, "B"=>76, "C"=>72}
    results["A"].should be_within(15).of(150)
    results["B"].should be_within( 8).of( 75)
    results["C"].should be_within( 8).of( 75)

    lambda{ @tree01.pick}.should raise_error(WeightedPicker::Tree::NoEntryError)
    lambda{ @tree02.pick}.should raise_error(WeightedPicker::Tree::NoEntryError)
  end

  it "should weigh item" do
    @tree00.weigh "A"
    @tree00.weights.should == [
      [6],
      [5,1],
      [4,1,1,0],
    ]
    @tree00.names_weights.should == {"A" => 4, "B" => 1, "C" => 1}
    lambda{ @tree00.weigh("D")}.should raise_error(WeightedPicker::Tree::NoEntryError)
  end

  it "should lighten item" do
    @tree00.lighten "A"
    @tree00.weights.should == [
      [3],
      [2,1],
      [1,1,1,0],
    ]
    @tree00.names_weights.should == {"A" => 1, "B" => 1, "C" => 1}
    lambda{ @tree00.lighten("D")}.should raise_error(WeightedPicker::Tree::NoEntryError)
  end

  it "should log2_ceil" do
    #lambda{ @tree00.log2_ceil(0)}.should raise_error(WeightedPicker::Tree::NoEntryError)
    @tree00.log2_ceil( 1).should == 0
    @tree00.log2_ceil( 2).should == 1
    @tree00.log2_ceil( 3).should == 2
    @tree00.log2_ceil( 4).should == 2
    @tree00.log2_ceil( 8).should == 3
    @tree00.log2_ceil(16).should == 4
    @tree00.log2_ceil(20).should == 5
  end

  #it "should choose" do
  #  @tree00.choose(1,2).should == 0
  #  @tree00.choose(1,2).should == 1
  #  @tree00.choose(1,2).should == 1
  #end

  it "should get index" do
    @tree00.index("A").should == 0
    @tree00.index("B").should == 1
    #lambda{ @tree00.find("C")}.should raise_error(WeightedPicker::Tree::NoEntryError)
  end

end
