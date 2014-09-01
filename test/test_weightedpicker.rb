# coding: utf-8

require 'helper'
require "test/unit"
require "stringio"
require "pp"
require "weightedpicker"

class WeightedPicker
    attr_accessor :weights
    public :merge
end

AB_YAML = "test/a256b128.yaml"
NOT_EXIST_FILE = "not_exist_file"


class TC_Weightedpicker < Test::Unit::TestCase
    def setup
        @wp00 = WeightedPicker.new({})
        @wp01 = WeightedPicker.load_file "test/a256b128.yaml"
        @wp02 = WeightedPicker.load_file "test/a512b64.yaml"
    end

    #describe "initialize" do
    def test_initialize
        #it "should create new file with data of 256 when the file not exist" do

        FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
        assert_raise( Errno::ENOENT) {
            WeightedPicker.load_file(NOT_EXIST_FILE)
        }
        FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE

        #it "should raise exception" do
        #    # 作成できないファイル名。
        #    lambda{WeightedPicker.load_file("")}.should raise_error(Errno::ENOENT)
        #end

        #it "should read correctly" do
        assert_equal( { "A" => 256, "B" => 128, }, @wp01.names_weights)
        assert_equal( { "A" => 512, "B" =>  64, }, @wp02.names_weights)

        #it "should treat as MAX_WEIGHT when the values are over the MAX_WEIGHT" do
        assert_equal(
            WeightedPicker.load_file("test/a99999b64.yaml").names_weights,
            { "A" => 65536, "B" => 64, }
        )

        #it "should treat as 0 when the values are negative" do
        assert_equal(
            { "A" => 0, "B" => 256, },
            WeightedPicker.load_file("test/a-1b256.yaml").names_weights
        )

        #New item is set by max values in alive entries.
        #it "should merge when keys between weights and items" do
        @wp01.merge(["B","C"])
        assert_equal({ "B" => 128, "C" => 256, }, @wp01.names_weights)

        @wp02.merge(["B","C"])
        assert_equal({ "B" =>  64, "C" => 256, }, @wp02.names_weights)

        #New item is set by max values in alive entries.
        #it "should merge when keys between weights and items" do
        setup
        @wp01.merge(["A","C"])
        assert_equal({ "A" => 256, "C" => 256, },@wp01.names_weights)
        @wp02.merge(["A","C"])
        assert_equal({ "A" => 512, "C" => 512, },@wp02.names_weights)

        #it "should raise exception if include not integer weight." do
        weights = { "A" => 1.0, "B" => 0.5, }
        assert_raise(WeightedPicker::InvalidWeightError) {
            WeightedPicker.load_file("test/float.yaml")
        }

        def teardown
            #FileUtils.rm AB_YAML    if File.exist? AB_YAML
            FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
        end
    end

    #before do
    #    @wp01 = WeightedPicker.load_file(AB_YAML)
    #    @wp00 = WeightedPicker.new({})
    #end

    #describe "pick" do
    def test_pick
        srand(0)
        #it "should pick" do
        assert_raise(WeightedPicker::Tree::NoEntryError) { @wp00.pick}

        results = {"A" => 0, "B" => 0}
        300.times do |i|
            results[@wp01.pick] += 1
        end
        #pp @wp01.names_weights #=> {"A"=>256, "B"=>128}
        assert(180 < results["A"])
        assert(results["A"] < 220)
        assert( 90 < results["B"])
        assert( results["B"] < 110)
    end

    #describe "weigh" do
    def test_weigh
        #it "should weigh A" do
        @wp01.weigh("A")
        assert_equal({ "A" => 512, "B" => 128 }, @wp01.names_weights)

        #it "should weigh B" do
        setup
        @wp01.weigh("B")
        assert_equal( { "A" => 256, "B" => 256 }, @wp01.names_weights)

        #it "should raise error" do
        assert_raise(WeightedPicker::Tree::NoEntryError) {
            Marshal.load(Marshal.dump(@wp01)).weigh("C")}
    end

    #describe "Weightedpicker::lighten" do
    def test_lighten
        #before do
        #    @wp01 = WeightedPicker.load_file(AB_YAML)
        #end

        #it "should lighten A" do
        t = Marshal.load(Marshal.dump(@wp01))
        t.lighten("A")
        assert_equal( { "A" => 128, "B" => 128 }, t.names_weights)

        #it "should lighten B" do
        t = Marshal.load(Marshal.dump(@wp01))
        t.lighten("B")
        assert_equal( { "A" => 256, "B" => 64 }, t.names_weights)

        #it "should raise error" do
        t = Marshal.load(Marshal.dump(@wp01))
        assert_raise(WeightedPicker::Tree::NoEntryError) {t.lighten("C")}


        #describe "include zero weight" do
        #it "should not change zero weight." do
        wp01 = WeightedPicker.load_file("test/a256b0.yaml")
        assert_equal( { "A" => 256, "B" => 0 }, wp01.names_weights)
        wp01.lighten("A")
        assert_equal( { "A" => 128, "B" => 0 }, wp01.names_weights)
        wp01.weigh("A")
        assert_equal( { "A" => 256, "B" => 0 }, wp01.names_weights)
        wp01.lighten("B")
        assert_equal( { "A" => 256, "B" => 0 }, wp01.names_weights)
        wp01.weigh("B")
        assert_equal( { "A" => 256, "B" => 0 }, wp01.names_weights)

        #describe "include one weight" do
        #it "should not change zero weight." do
        wp01 = WeightedPicker.load_file("test/a256b1.yaml")

        assert_equal({ "A" => 256, "B" => 1 }, wp01.names_weights)

        wp01.lighten("A")
        assert_equal({ "A" => 128, "B" => 1 }, wp01.names_weights)

        wp01.weigh("A")
        assert_equal({ "A" => 256, "B" => 1 }, wp01.names_weights)

        wp01.lighten("B")
        assert_equal({ "A" => 256, "B" => 1 }, wp01.names_weights)

        wp01.weigh("B")
        assert_equal({ "A" => 256, "B" => 2 }, wp01.names_weights)
    end

    #describe "Weightedpicker::dump" do
    def test_dump
        #it "should dump yaml." do
        io = StringIO.new
        @wp01.dump(io)
        io.rewind
        results = YAML.load(io)
        assert_equal({ "A" => 256, "B" => 128, },results)
    end

    #describe "Weightedpicker::names" do
    def test_names
        #it "should return an array of names." do
        assert_equal([ "A", "B"], @wp01.names)
    end

    #describe "Weightedpicker::dump_histgram" do
    def test_dump_histgram
        #it "should output histgram to io." do
        input = {}
        4.times do |power|
            num = 10**power
            num.times do |i|
                input["#{power}_#{i}"] = num
            end
        end
        wp20 = WeightedPicker.new(input)
        io = StringIO.new
        wp20.dump_histgram(io)
        io.rewind
        result = io.read
        correct = [
            "     1(   1)|*",
            "     2(   0)|",
            "     4(   0)|",
            "     8(   0)|",
            "    16(  10)|*",
            "    32(   0)|",
            "    64(   0)|",
            "   128( 100)|*****",
            "   256(   0)|",
            "   512(   0)|",
            "  1024(1000)|**************************************************",
            "  2048(   0)|",
            "  4096(   0)|",
            "  8192(   0)|",
            " 16384(   0)|",
            " 32768(   0)|",
            " 65536(   0)|",
            ""
        ].join("\n")
        #pp result
        #pp correct
        assert_equal(correct, result)
    end

    #describe "Weightedpicker::total_weight" do
    #it "should output histgram to io." do
    def test_total_weight
        assert_equal(0  , @wp00.total_weight)
        assert_equal(384, @wp01.total_weight)
        assert_equal(576, @wp02.total_weight)
    end
end

