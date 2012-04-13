require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require "stringio"
require "fileutils"

class WeightedPicker
  attr_accessor :weights
  public :normalize_write, :adopt?, :merge
end

TMP_FILE = "tmp.yaml"
NOT_EXIST_FILE = "not_exist_file"



describe "Weightedpicker::initialize" do
  before do
    weights = { "A" => 1.0, "B" => 0.5, }
    items = ["A", "B"]
    File.open(TMP_FILE, "w") { |io| YAML.dump(weights, io) }
    @wp01 = WeightedPicker.new(TMP_FILE, items)
    @wp02 = Marshal.load(Marshal.dump(@wp01))
    @wp02.weights = {}
    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

  it "should create new file when the file not exist" do
    # 指定したファイルが存在しない場合、
    t = WeightedPicker.new(NOT_EXIST_FILE, ["A","B"])
    t.weights.should == { "A" => 1.0, "B" => 1.0}
    YAML.load_file(NOT_EXIST_FILE).should == { "A" => 1.0, "B" => 1.0, }
  end
  
  it "should raise exception" do
    # 作成できないファイル名。
    lambda{WeightedPicker.new("", ["A","B"])}.should raise_error(Errno::ENOENT)
  end

  it "should read correctly" do
    # 正しく取り込めているか？
    @wp01.weights.should == { "A" => 1.0, "B" => 0.5, }
  end

  it "should normalize when the maximum in the file not the same as MAX_WEIGHT" do
    # 指定したファイル内の重みの最大値が MAX_WEIGHT と異なれば、
    # 全体を normalize して格納。
    weights = { "A" => 2.0, "B" => 0.5, }
    File.open(TMP_FILE, "w") {|io| YAML.dump(weights, io) }
    WeightedPicker.new(TMP_FILE, ["A","B"]).weights.should == { "A" => 1.0, "B" => 0.25, }
    #
    weights = { "A" => 0.25, "B" => 0.5, }
    File.open(TMP_FILE, "w"){ |io| YAML.dump(weights, io) }
    WeightedPicker.new(TMP_FILE, ["A","B"]).weights.should == { "A" => 0.5, "B" => 1.0, }
  end

  it "should merge when keys between weights and items" do
    # weights と items が異なる場合
    weights = { "A" => 1.0, "B" => 0.50, }
    File.open(TMP_FILE, "w") {|io| YAML.dump(weights, io) }
    WeightedPicker.new(TMP_FILE, ["B","C"]).weights.should == { "B" => 0.5, "C" => 1.0, }
  end

  after do
    FileUtils.rm TMP_FILE  if File.exist? TMP_FILE
    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

end

describe "Weightedpicker::merge" do
  before do
    weights = { "A" => 1.0, "B" => 0.5, }
    items = ["A", "B"]
    File.open(TMP_FILE, "w") { |io| YAML.dump(weights, io) }
    @wp01 = WeightedPicker.new(TMP_FILE, items)

    @wp02 = Marshal.load(Marshal.dump(@wp01))
    @wp02.weights = {}

    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

  it "when keys given are less than weights file" do
    # 少ない場合
    t = Marshal.load(Marshal.dump(@wp01))
    keys = ["B"]
    t.merge(keys)
    t.weights. should == { "B" => 1.0 }
    # 書き込みチェック
    YAML.load_file(TMP_FILE).should == { "B" => 1.0 }
  end

  it "when keys given are more than weights file" do
    # 多い場合
    t = Marshal.load(Marshal.dump(@wp01))
    keys = ["A", "B", "C"]
    t.merge(keys)
    t.weights.should == { "A" => 1.0, "B" => 0.5, "C" => 1.0, }
    # 書き込みチェック
    YAML.load_file(TMP_FILE).should == { "A" => 1.0, "B" => 0.5, "C" => 1.0}
  end

  it "when keys given are the same as weights file" do
    t = Marshal.load(Marshal.dump(@wp01))
    # 同じ場合
    keys = ["A", "B"]
    t.merge(keys)
    t.weights.should == { "A" => 1.0, "B" => 0.5}
    # 書き込みチェック
    YAML.load_file(TMP_FILE).should == { "A" => 1.0, "B" => 0.5}
  end

  after do
    FileUtils.rm TMP_FILE  if File.exist? TMP_FILE
    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

end

describe "Weightedpicker::pick" do
  before do
    weights = { "A" => 1.0, "B" => 0.5, }
    items = ["A", "B"]
    File.open(TMP_FILE, "w") { |io| YAML.dump(weights, io) }
    @wp01 = WeightedPicker.new(TMP_FILE, items)

    @wp02 = Marshal.load(Marshal.dump(@wp01))
    @wp02.weights = {}

    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

  it "should pick" do
    ## No test, beccause including randomness.
    #assert_raise(WeightedPicker::NoEntryError){@wp02.pick}
    #100.times do 
    #  assert_equal(true, ["A","B"].include?(@wp01.pick))
    #end
  end

  after do
    FileUtils.rm TMP_FILE  if File.exist? TMP_FILE
    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

end

describe "Weightedpicker::weigh" do
  before do
    weights = { "A" => 1.0, "B" => 0.5, }
    items = ["A", "B"]
    File.open(TMP_FILE, "w") { |io| YAML.dump(weights, io) }
    @wp01 = WeightedPicker.new(TMP_FILE, items)
    @wp02 = Marshal.load(Marshal.dump(@wp01))
    @wp02.weights = {}

    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

  it "should weigh A" do
    t = Marshal.load(Marshal.dump(@wp01))
    t.weigh("A")
    t.weights.should == { "A" => 1.0, "B" => 0.25 }
    # 書き込みチェック
    YAML.load_file(TMP_FILE).should == { "A" => 1.0, "B" => 0.25 }
  end

  it "should weigh B" do
    t = Marshal.load(Marshal.dump(@wp01))
    t.weigh("B")
    t.weights.should == { "A" => 1.0, "B" => 1.0 }
    # 書き込みチェック
    YAML.load_file(TMP_FILE).should == { "A" => 1.0, "B" => 1.0 }
  end

  it "should raise error" do
    lambda{Marshal.load(Marshal.dump(@wp01)).weigh("C")}.should raise_error(WeightedPicker::NotExistKeyError)
  end

  after do
    FileUtils.rm TMP_FILE  if File.exist? TMP_FILE
    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

end

describe "Weightedpicker::lighten" do
  before do
    weights = { "A" => 1.0, "B" => 0.5, }
    items = ["A", "B"]
    File.open(TMP_FILE, "w") { |io| YAML.dump(weights, io) }
    @wp01 = WeightedPicker.new(TMP_FILE, items)
    @wp02 = Marshal.load(Marshal.dump(@wp01))
    @wp02.weights = {}
    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

  it "should lighten A" do
    t = Marshal.load(Marshal.dump(@wp01))
    t.lighten("A")
    t.weights.should == { "A" => 1.0, "B" => 1.0 }
    # 書き込みチェック
    YAML.load_file(TMP_FILE).should == { "A" => 1.0, "B" => 1.0 }
  end

  it "should lighten B" do
    t = Marshal.load(Marshal.dump(@wp01))
    t.lighten("B")
    t.weights.should == { "A" => 1.0, "B" => 0.25 }
    # 書き込みチェック
    YAML.load_file(TMP_FILE).should == { "A" => 1.0, "B" => 0.25 }
  end

  it "should raise error" do
    t = Marshal.load(Marshal.dump(@wp01))
    lambda{t.lighten("C")}.should raise_error(WeightedPicker::NotExistKeyError)
  end

  after do
    FileUtils.rm TMP_FILE  if File.exist? TMP_FILE
    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

end

describe "Weightedpicker::adopt" do
  before do
    weights = { "A" => 1.0, "B" => 0.5, }
    items = ["A", "B"]
    File.open(TMP_FILE, "w") { |io| YAML.dump(weights, io) }
    @wp01 = WeightedPicker.new(TMP_FILE, items)
    @wp02 = Marshal.load(Marshal.dump(@wp01))
    @wp02.weights = {}
    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

  it do
    @wp01.adopt?("A", 0.0  ).should be_true
    @wp01.adopt?("A", 0.5  ).should be_true
    @wp01.adopt?("A", 0.999).should be_true
    @wp01.adopt?("A", 1.0  ).should be_false
    @wp01.adopt?("B", 0.0  ).should be_true
    @wp01.adopt?("B", 0.499).should be_true
    @wp01.adopt?("B", 0.5  ).should be_false
    @wp01.adopt?("B", 1.0  ).should be_false
  end

  after do
    FileUtils.rm TMP_FILE  if File.exist? TMP_FILE
    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

end

describe "Weightedpicker::normalize_write" do
  before do
    weights = { "A" => 1.0, "B" => 0.5, }
    items = ["A", "B"]
    File.open(TMP_FILE, "w") { |io| YAML.dump(weights, io) }
    @wp01 = WeightedPicker.new(TMP_FILE, items)
    @wp02 = Marshal.load(Marshal.dump(@wp01))
    @wp02.weights = {}
    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

  it "should shrink write" do
    t = Marshal.load(Marshal.dump(@wp01))
    t.weights = { "A" => 2.0, "B" => 0.5, }
    t.normalize_write
    t.weights.should == { "A" => 1.0, "B" => 0.25}
    # 書き込みチェック
    YAML.load_file(TMP_FILE).should == { "A" => 1.0, "B" => 0.25}
  end

  it "should shrink write" do
    t = Marshal.load(Marshal.dump(@wp01))
    t.weights = { "A" => 0.5, "B" => 0.5, }
    t.normalize_write
    t.weights.should == { "A" => 1.0, "B" => 1.00}
    # 書き込みチェック
    YAML.load_file(TMP_FILE).should == { "A" => 1.0, "B" => 1.00}
  end

  it "should raise error" do
    lambda{@wp02.normalize_write}.should raise_error (WeightedPicker::NoEntryError)
  end

  after do
    FileUtils.rm TMP_FILE  if File.exist? TMP_FILE
    FileUtils.rm NOT_EXIST_FILE if File.exist? NOT_EXIST_FILE
  end

end
