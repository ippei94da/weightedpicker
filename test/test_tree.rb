# coding: utf-8
require 'helper'
require "test/unit"
require "stringio"
require "weightedpicker"

class WeightedPicker::Tree
    public :log2_ceil
    public :depth
    public :choose
    public :index
    public :add_ancestors
    attr_reader :weights
end

#describe "Weightedpicker::Tree" do
class TC_Weightedpicker_Tree < Test::Unit::TestCase
    def setup
        @tree00 = WeightedPicker::Tree.new({"A" => 2, "B" => 1, "C" => 1})
        @tree01 = WeightedPicker::Tree.new({"A" => 0})
        @tree02 = WeightedPicker::Tree.new({})
    end

    def test_names_weights
        #it "should return a hash of names_weights" do
        assert_equal({"A" => 2, "B" => 1, "C" => 1} , @tree00.names_weights)

        #it "should weigh item" do
        @tree00.weigh "A"
        assert_equal( [ [6], [5,1], [4,1,1,0], ], @tree00.weights)
        assert_equal( {"A" => 4, "B" => 1, "C" => 1}, @tree00.names_weights)
        assert_raise(WeightedPicker::Tree::NoEntryError) { @tree00.weigh("D")}
    end


    #it "should pick" do
    def test_pick
        results = {"A" => 0, "B" => 0, "C" => 0}
        srand(0)
        300.times do |i|
            results[@tree00.pick] += 1
        end
        assert(125 < results["A"])
        assert(results["A"] < 175)
        assert(65    < results["B"])
        assert(results["B"] <    85)
        assert(65    < results["C"])
        assert(results["C"] <    85)
        #pp results #=> {"A"=> 52, "B"=>76, "C"=>72}
        #assert(results["A"].should be_within(15).of(150)
        #assert(results["B"].should be_within( 8).of( 75)
        #assert(results["C"].should be_within( 8).of( 75)

        assert_raise(WeightedPicker::Tree::NoEntryError) { @tree01.pick}
        assert_raise(WeightedPicker::Tree::NoEntryError) { @tree02.pick}
    end

    #it "should weigh item, but be limited by MAX" do
    def test_weigh
        tree10 = WeightedPicker::Tree.new({"A" => 60000, "B" => 1, "C" => 1})

        tree10.weigh "A"
        assert_equal( [ [65538], [65537,1], [65536,1,1,0], ], tree10.weights)
        assert_equal( {"A" => 65536, "B" => 1, "C" => 1}, tree10.names_weights)
    end

    def test_lighten
        #it "should lighten item" do
        @tree00.lighten "A"
        assert_equal( [ [3], [2,1], [1,1,1,0], ], @tree00.weights)
        assert_equal( {"A" => 1, "B" => 1, "C" => 1}, @tree00.names_weights)
        assert_raise(WeightedPicker::Tree::NoEntryError){ @tree00.lighten("D")}

        #it "should lighten item, but be limited by MIN" do
        setup
        @tree00.lighten "B"
        assert_equal([ [4], [3,1], [2,1,1,0], ]    , @tree00.weights      )
        assert_equal({"A" => 2, "B" => 1, "C" => 1}, @tree00.names_weights)
    end


    #it "should add_ancestors" do
    def test_weights
        @tree00.add_ancestors(1,10)
        assert_equal([ [14], [13,1], [2,11,1,0], ], @tree00.weights)
    end

    #it "should log2_ceil" do
    def test_log2_cell
        #lambda{ @tree00.log2_ceil(0)}.should raise_error(WeightedPicker::Tree::NoEntryError)
        assert_equal( 0, @tree00.log2_ceil( 1))
        assert_equal( 1, @tree00.log2_ceil( 2))
        assert_equal( 2, @tree00.log2_ceil( 3))
        assert_equal( 2, @tree00.log2_ceil( 4))
        assert_equal( 3, @tree00.log2_ceil( 8))
        assert_equal( 4, @tree00.log2_ceil(16))
        assert_equal( 5, @tree00.log2_ceil(20))
    end

    #it "should choose" do
    #    @tree00.choose(1,2).should == 0
    #    @tree00.choose(1,2).should == 1
    #    @tree00.choose(1,2).should == 1
    #end

    #it "should get index" do
    def test_index
        assert_equal( 0, @tree00.index("A"))
        assert_equal( 1, @tree00.index("B"))
        #lambda{ @tree00.find("C")}.should raise_error(WeightedPicker::Tree::NoEntryError)
    end

    #it "should get total weight" do
    def test_total_weight
        assert_equal( 4, @tree00.total_weight)
        assert_equal( 0, @tree01.total_weight)
        assert_equal( 0, @tree02.total_weight)
    end
end

