require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require "stringio"
require "fileutils"

class WeightedPicker
  attr_accessor :weights
  public :normalize_write, :merge
end

AB_YAML = "spec/a256b128.yaml"
NOT_EXIST_FILE = "not_exist_file"



describe "Weightedpicker::initialize" do
  before do
  #  weights = { "A" => 256, "B" => 128, }
  #  items = ["A", "B"]
    @wp01 = WeightedPicker.new("spec/a256b128.yaml", items)
    @wp03 = WeightedPicker.new("spec/a512b64.yaml", items)

  #  @wp02 = Marshal.load(Marshal.dump(@wp01))
  #  @wp02.weights = {}
  end

  it "should create new file with data of 256 when the file not exist" do
    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
    t = WeightedPicker.new(NOT_EXIST_FILE, ["A","B"])
    t.weights.should == { "A" => 256, "B" => 256}
    YAML.load_file(NOT_EXIST_FILE).should == {
      "A" => 256,
      "B" => 256,
    }
    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end
  
  it "should raise exception" do
    # 作成できないファイル名。
    lambda{WeightedPicker.new("", ["A","B"])}.should raise_error(Errno::ENOENT)
  end

  it "should read correctly" do
    # 正しく取り込めているか？
    @wp01.weights.should == { "A" => 256, "B" => 128, }
    @wp03.weights.should == { "A" => 512, "B" =>  64, }
  end

  it "should treat as MAX_WEIGHT when the values are over the MAX_WEIGHT" do
    #Not write
    WeightedPicker.new("spec/a99999b64.yaml", ["A","B"]).weights.should == { "A" => 65536, "B" => 64, }
  end

  it "should treat as 0 when the values are negative" do
    #Not write
    WeightedPicker.new("spec/a-1b256.yaml", ["A","B"]).weights.should == { "A" => 0, "B" => 256, }
  end

  #New item is set by max values in alive entries.
  it "should merge when keys between weights and items" do
    WeightedPicker.new(AB_YAML, ["B","C"]).weights.should == { "B" => 128, "C" => 256, }

    WeightedPicker.new("spec/a512b64.yaml", ["B","C"]).weights.should == { "B" => 64, "C" => 64, }
  end

  it "should raise exception if include not integer weight." do
    weights = { "A" => 1.0, "B" => 0.5, }
    lambda{
      WeightedPicker.new("float.yaml", ["A","B"])
    }.should raise_error(WeightedPicker::InvalidWeightError)
  end

  after do
    FileUtils.rm AB_YAML  if File.exist? AB_YAML
    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

end

#describe "Weightedpicker::merge" do
#  before do
#    @wp01 = WeightedPicker.new(AB_YAML, items)
#
#    #@wp02 = Marshal.load(Marshal.dump(@wp01))
#    #@wp02.weights = {}
#
#    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
#  end
#
#  it "when keys given are less than weights file" do
#    # 少ない場合
#    t = Marshal.load(Marshal.dump(@wp01))
#    keys = ["B"]
#    t.merge(keys)
#    t.weights. should == { "B" => 256 }
#    # 書き込みチェック
#    YAML.load_file(AB_YAML).should == { "B" => 256 }
#  end
#
#  it "when keys given are more than weights file" do
#    # 多い場合
#    t = Marshal.load(Marshal.dump(@wp01))
#    keys = ["A", "B", "C"]
#    t.merge(keys)
#    t.weights.should == { "A" => 256, "B" => 128, "C" => 256, }
#    # 書き込みチェック
#    YAML.load_file(AB_YAML).should == { "A" => 256, "B" => 128, "C" => 256}
#  end
#
#  it "when keys given are the same as weights file" do
#    t = Marshal.load(Marshal.dump(@wp01))
#    # 同じ場合
#    keys = ["A", "B"]
#    t.merge(keys)
#    t.weights.should == { "A" => 256, "B" => 128}
#    # 書き込みチェック
#    YAML.load_file(AB_YAML).should == { "A" => 256, "B" => 128}
#  end
#
#  after do
#    FileUtils.rm AB_YAML  if File.exist? AB_YAML
#    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
#  end
#
#end

describe "Weightedpicker::pick" do
  before do
    weights = { "A" => 256, "B" => 128, }
    items = ["A", "B"]
    File.open(AB_YAML, "w") { |io| YAML.dump(weights, io) }
    @wp01 = WeightedPicker.new(AB_YAML, items)

    @wp02 = Marshal.load(Marshal.dump(@wp01))
    @wp02.weights = {}

    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

  it "should pick" do
    lambda{@wp02.pick}.should raise_error(WeightedPicker::NoEntryError)

    sum = 1_128
    tryal = 300
    results = {"A" => 0, "B" => 0}
    tryal.times do |i|
      results[@wp01.pick(i * sum / tryal)] += 1
    end
    results["A"].should == tryal / 3 * 2
    results["B"].should == tryal / 3 * 1
  end

  after do
    FileUtils.rm AB_YAML  if File.exist? AB_YAML
    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

end

describe "Weightedpicker::weigh" do
  before do
    weights = { "A" => 256, "B" => 128, }
    items = ["A", "B"]
    File.open(AB_YAML, "w") { |io| YAML.dump(weights, io) }
    @wp01 = WeightedPicker.new(AB_YAML, items)
    @wp02 = Marshal.load(Marshal.dump(@wp01))
    @wp02.weights = {}

    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

  it "should weigh A" do
    t = Marshal.load(Marshal.dump(@wp01))
    t.weigh("A")
    t.weights.should == { "A" => 256, "B" => 64 }
    # 書き込みチェック
    YAML.load_file(AB_YAML).should == { "A" => 256, "B" => 64 }
  end

  it "should weigh B" do
    t = Marshal.load(Marshal.dump(@wp01))
    t.weigh("B")
    t.weights.should == { "A" => 256, "B" => 256 }
    # 書き込みチェック
    YAML.load_file(AB_YAML).should == { "A" => 256, "B" => 256 }
  end

  it "should raise error" do
    lambda{Marshal.load(Marshal.dump(@wp01)).weigh("C")}.should raise_error(WeightedPicker::NotExistKeyError)
  end

  after do
    FileUtils.rm AB_YAML  if File.exist? AB_YAML
    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

end

describe "Weightedpicker::lighten" do
  before do
    weights = { "A" => 256, "B" => 128, }
    items = ["A", "B"]
    File.open(AB_YAML, "w") { |io| YAML.dump(weights, io) }
    @wp01 = WeightedPicker.new(AB_YAML, items)
    @wp02 = Marshal.load(Marshal.dump(@wp01))
    @wp02.weights = {}
    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

  it "should lighten A" do
    t = Marshal.load(Marshal.dump(@wp01))
    t.lighten("A")
    t.weights.should == { "A" => 256, "B" => 256 }
    # 書き込みチェック
    YAML.load_file(AB_YAML).should == { "A" => 256, "B" => 256 }
  end

  it "should lighten B" do
    t = Marshal.load(Marshal.dump(@wp01))
    t.lighten("B")
    t.weights.should == { "A" => 256, "B" => 64 }
    # 書き込みチェック
    YAML.load_file(AB_YAML).should == { "A" => 256, "B" => 64 }
  end

  it "should raise error" do
    t = Marshal.load(Marshal.dump(@wp01))
    lambda{t.lighten("C")}.should raise_error(WeightedPicker::NotExistKeyError)
  end

  after do
    FileUtils.rm AB_YAML  if File.exist? AB_YAML
    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

end

describe "Weightedpicker::normalize_write" do
  before do
    weights = { "A" => 256, "B" => 128, }
    items = ["A", "B"]
    File.open(AB_YAML, "w") { |io| YAML.dump(weights, io) }
    @wp01 = WeightedPicker.new(AB_YAML, items)
    @wp02 = Marshal.load(Marshal.dump(@wp01))
    @wp02.weights = {}
    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

  it "should shrink write" do
    t = Marshal.load(Marshal.dump(@wp01))
    t.weights = { "A" => 512, "B" => 128, }
    t.normalize_write
    t.weights.should == { "A" => 256, "B" => 64}
    # 書き込みチェック
    YAML.load_file(AB_YAML).should == { "A" => 256, "B" => 64}
  end

  it "should shrink write with 2" do
    t = Marshal.load(Marshal.dump(@wp01))
    t.weights = { "A" => 512, "B" => 2, }
    t.normalize_write
    t.weights.should == { "A" => 256, "B" => 1}
  end

  it "should shrink write with 1" do
    t = Marshal.load(Marshal.dump(@wp01))
    t.weights = { "A" => 512, "B" => 1, }
    t.normalize_write
    t.weights.should == { "A" => 256, "B" => 1}
  end

  it "should shrink write with 0" do
    t = Marshal.load(Marshal.dump(@wp01))
    t.weights = { "A" => 512, "B" => 0, }
    t.normalize_write
    t.weights.should == { "A" => 256, "B" => 0}
  end

  it "should expand write" do
    t = Marshal.load(Marshal.dump(@wp01))
    t.weights = { "A" => 128, "B" => 128, }
    t.normalize_write
    t.weights.should == { "A" => 256, "B" => 256}
    # 書き込みチェック
    YAML.load_file(AB_YAML).should == { "A" => 256, "B" => 256}
  end

  it "should raise error" do
    lambda{@wp02.normalize_write}.should raise_error (WeightedPicker::NoEntryError)
  end

  after do
    FileUtils.rm AB_YAML  if File.exist? AB_YAML
    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

end

describe "include zero weight" do
  before do
    weights = { "A" => 256, "B" => 0, }
    items = ["A", "B"]
    File.open(AB_YAML, "w") { |io| YAML.dump(weights, io) }
    @wp01 = WeightedPicker.new(AB_YAML, items)
    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

  it "should not change zero weight." do
    @wp01.weights.should == { "A" => 256, "B" => 0 }
    @wp01.lighten("A")
    @wp01.weights.should == { "A" => 256, "B" => 0 }
    @wp01.weigh("A")
    @wp01.weights.should == { "A" => 256, "B" => 0 }
    @wp01.lighten("B")
    @wp01.weights.should == { "A" => 256, "B" => 0 }
    @wp01.weigh("B")
    @wp01.weights.should == { "A" => 256, "B" => 0 }
  end

  after do
    FileUtils.rm AB_YAML  if File.exist? AB_YAML
    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

end

describe "include one weight" do
  before do
    weights = { "A" => 256, "B" => 1, }
    items = ["A", "B"]
    File.open(AB_YAML, "w") { |io| YAML.dump(weights, io) }
    @wp01 = WeightedPicker.new(AB_YAML, items)
    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

  it "should not change zero weight." do
    @wp01.weights.should == { "A" => 256, "B" => 1 }

    @wp01.lighten("A")
    @wp01.weights.should == { "A" => 256, "B" => 2 }

    @wp01.weigh("A")
    @wp01.weights.should == { "A" => 256, "B" => 1 }

    @wp01.lighten("B")
    @wp01.weights.should == { "A" => 256, "B" => 1 }

    @wp01.weigh("B")
    @wp01.weights.should == { "A" => 256, "B" => 2 }
  end

  after do
    FileUtils.rm AB_YAML  if File.exist? AB_YAML
    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

end

