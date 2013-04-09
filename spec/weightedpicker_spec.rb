require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require "stringio"
require "fileutils"

class WeightedPicker
  attr_accessor :weights
  public :merge
end

AB_YAML = "spec/a256b128.yaml"
NOT_EXIST_FILE = "not_exist_file"



describe "Weightedpicker" do
  before do
    @wp00 = WeightedPicker.new({})
    @wp01 = WeightedPicker.load_file "spec/a256b128.yaml"
    @wp02 = WeightedPicker.load_file "spec/a512b64.yaml"
  end

  describe "initialize" do
    it "should create new file with data of 256 when the file not exist" do
      FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
      lambda{
        WeightedPicker.load_file(NOT_EXIST_FILE)
      }.should raise_error(Errno::ENOENT)
      FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
    end

    #it "should raise exception" do
    #  # 作成できないファイル名。
    #  lambda{WeightedPicker.load_file("")}.should raise_error(Errno::ENOENT)
    #end

    it "should read correctly" do
      # 正しく取り込めているか？
      @wp01.weights.should == { "A" => 256, "B" => 128, }
      @wp02.weights.should == { "A" => 512, "B" =>  64, }
    end

    it "should treat as MAX_WEIGHT when the values are over the MAX_WEIGHT" do
      #Not write
      WeightedPicker.load_file("spec/a99999b64.yaml").weights.should == { "A" => 65536, "B" => 64, }
    end

    it "should treat as 0 when the values are negative" do
      #Not write
      WeightedPicker.load_file("spec/a-1b256.yaml").weights.should == { "A" => 0, "B" => 256, }
    end

    #New item is set by max values in alive entries.
    it "should merge when keys between weights and items" do
      @wp01.merge(["B","C"])
      @wp01.weights.should == { "B" => 128, "C" => 256, }
      @wp02.merge(["B","C"])
      @wp02.weights.should == { "B" =>  64, "C" => 256, }
    end

    #New item is set by max values in alive entries.
    it "should merge when keys between weights and items" do
      @wp01.merge(["A","C"])
      @wp01.weights.should == { "A" => 256, "C" => 256, }
      @wp02.merge(["A","C"])
      @wp02.weights.should == { "A" => 512, "C" => 512, }
    end

    it "should raise exception if include not integer weight." do
      weights = { "A" => 1.0, "B" => 0.5, }
      lambda{
        WeightedPicker.load_file("spec/float.yaml")
      }.should raise_error(WeightedPicker::InvalidWeightError)
    end

    after do
      #FileUtils.rm AB_YAML  if File.exist? AB_YAML
      FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
    end
  end

  #before do
  #  @wp01 = WeightedPicker.load_file(AB_YAML)
  #  @wp00 = WeightedPicker.new({})
  #end

  describe "pick" do
    srand(0)
    it "should pick" do
      lambda{@wp00.pick}.should raise_error(WeightedPicker::NoEntryError)

      tryal = 256 + 128
      results = {"A" => 0, "B" => 0}
      tryal.times do |i|
        results[@wp01.pick(i)] += 1
      end
      results["A"].should == tryal / 3 * 2
      results["B"].should == tryal / 3 * 1
    end
  end


  describe "weigh" do
    it "should weigh A" do
      @wp01.weigh("A")
      @wp01.weights.should == { "A" => 512, "B" => 128 }
    end

    it "should weigh B" do
      @wp01.weigh("B")
      @wp01.weights.should == { "A" => 256, "B" => 256 }
    end

    it "should raise error" do
      lambda{Marshal.load(Marshal.dump(@wp01)).weigh("C")}.should raise_error(WeightedPicker::NotExistKeyError)
    end

  end

  describe "Weightedpicker::lighten" do
    #before do
    #  @wp01 = WeightedPicker.load_file(AB_YAML)
    #end

    it "should lighten A" do
      t = Marshal.load(Marshal.dump(@wp01))
      t.lighten("A")
      t.weights.should == { "A" => 128, "B" => 128 }
    end

    it "should lighten B" do
      t = Marshal.load(Marshal.dump(@wp01))
      t.lighten("B")
      t.weights.should == { "A" => 256, "B" => 64 }
    end

    it "should raise error" do
      t = Marshal.load(Marshal.dump(@wp01))
      lambda{t.lighten("C")}.should raise_error(WeightedPicker::NotExistKeyError)
    end

  end

  describe "include zero weight" do
    it "should not change zero weight." do
      wp01 = WeightedPicker.load_file("spec/a256b0.yaml")
      wp01.weights.should == { "A" => 256, "B" => 0 }
      wp01.lighten("A")
      wp01.weights.should == { "A" => 128, "B" => 0 }
      wp01.weigh("A")
      wp01.weights.should == { "A" => 256, "B" => 0 }
      wp01.lighten("B")
      wp01.weights.should == { "A" => 256, "B" => 0 }
      wp01.weigh("B")
      wp01.weights.should == { "A" => 256, "B" => 0 }
    end

  end

  describe "include one weight" do
    it "should not change zero weight." do
      wp01 = WeightedPicker.load_file("spec/a256b1.yaml")

      wp01.weights.should == { "A" => 256, "B" => 1 }

      wp01.lighten("A")
      wp01.weights.should == { "A" => 128, "B" => 1 }

      wp01.weigh("A")
      wp01.weights.should == { "A" => 256, "B" => 1 }

      wp01.lighten("B")
      wp01.weights.should == { "A" => 256, "B" => 1 }

      wp01.weigh("B")
      wp01.weights.should == { "A" => 256, "B" => 2 }
    end

  end

  describe "Weightedpicker::dump" do
    it "should dump yaml." do
      io = StringIO.new
      @wp01.dump(io)
      io.rewind
      results = YAML.load(io)
      results.should == { "A" => 256, "B" => 128, }

    end

  end

end

