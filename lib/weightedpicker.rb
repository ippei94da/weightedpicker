# coding: utf-8
require 'yaml'

class WeightedPicker; end

require 'weightedpicker/tree.rb'

# TODO
#       initialize.指定したファイル内のデータが WeightedPicker 的に
#       解釈できなければ例外。

#= 概要
# 要素群の中から、優先度に応じた重み付きランダムで、
# どれか1つを選択する。
# たとえば、以下の用途に使える。
#* 音楽ファイルの再生(好みのものは多い頻度で、
#    そうでないものは少ない頻度で)
#* クイズゲームの問題選択
#* 画像
#    * 写真で壁紙, スライドショー的な用途。
#
# 対象の要素はファイルであることを前提としない。
# 文字列であることが多いかもしれない。
#
#= 確率として評価を保存
# 全ての要素の好ましさを点数として記録。
# 対象要素全てで好ましさを総和したものが母数、
# それに対する要素の点数/点数の総和 がその要素の選択される確率。
#
#= 保存ファイルが必要
# 保存ファイル名を必ず保持する。
# 当クラスは、中長期的に使用することで選択を賢くするのが目的。
# 現在の成績を保存しないということはほとんど考えられない。
#
#= 時間を評価関数に入れない
# 「対象の要素の好ましさの、好ましさの総量に対する割合」が
# その要素が選ばれる確率となる。
# 時間を評価に入れると構造が複雑になるし、
# 機会と時間は一般にそれほどよい相関がない。
# 毎日使うこともあれば、1ヶ月あくこともある。
#
#= 使用 != 鑑賞
# ライブラリの考え方としては使用=鑑賞とは仮定しない。
# 要素が pick された瞬間では点数操作は行わず、
# 明示的に点数操作が指示されたときだけ変化・保存する。
#
#= 加点と減点
# 点数操作が行われる度に規格化する。
#
#= 評価の上限と下限
#== 上限
# 点数の上限は 1 million。
# 上限を越える点数の要素が現れたら、
# それが max valueになるように全ての要素の評価を除算して正規化する。
#
#== 下限
# 点数の下限は 1 としておく。
# 下限を下回る点数の要素が現れたら、
# その要素の点数を下限値に設定する。
# これが重要になるのはクイズゲームで間違ったときにその問題以外の
# 評価が相対的に下がる現象。
# Ruby 1.9.1 において扱える最小の数を確認してみたところ、
# 2.0 **(-1074) # => 5.0e-324
# 2.0 **(-1075) # => 0.0
# となり、無限小の有限の数が扱えず、
# どこかで潰れて 0.0 になることが分かる。
# 指数 -500 は有限の数から 0.0 になる境界と
# 最頻値 1.0 の中間くらいの指数として選ばれた。
#
# 1/100万で人間的尺度では無視して良い確率だが、
# これを大きく下回る確率としている。
# 普通 500 回も間違えることは考えにくい。
# そして 500回間違えたとしても、
# 2.0 **(- 500) 精度で評価が保存可能。
#
# ただし、0.0 がセットされた要素はこれを下限値に修正したりはせず、
# 0.0 のままとする。
# これは たとえばメイドさんRnR のように自動的には選ばれて
# 欲しくないものだけど、ファイルを消すのは惜しいものを扱うため。
# また、既にデータ管理がなされていることを示す必要がある。
#
#= 連続選択を制限する方法は導入しない
# いろいろ複雑になる。
# とりあえずはこの仕組みを導入しない。
# これに対応するにはまず history をデータとして残す必要がある。
# また計算通りの確率から乱れない方法が好ましいが、
# そのような計算方法はぱっと思い付かない。
# 
# たとえば定数回以内の選択を拒否する仕組みでは、
# 重み 100 が1個(A)と重み1が1個(B)で全2個状態では、
# 連続を認めない(間に 1つ入れる必要あり)という場合では、
# 本来 99:1 で実行される筈なのに 1:1 になってしまう。
# 
# 間隔の期待値に定数を除算する方法も考えたが、
# 重み0のものはゼロ割りになるなど扱いが面倒になる。
# 
# ヒストリ関係はこのクラスの外に出した方が良いと判断。
class WeightedPicker
    MAX_WEIGHT = 2**16
    INI_WEIGHT = 2** 8
    MIN_WEIGHT = 2** 0

    HISTGRAM_WIDTH = 50

    class InvalidFilenameError < Exception; end
    class NoEntryError               < Exception; end
    class NotExistKeyError       < Exception; end
    class InvalidWeightError     < Exception; end

    # Initialization.
    def initialize(data)
        data = sanity_data(data)
        @tree = WeightedPicker::Tree.new(data)
    end

    # Argument 'file' indicates a strage file name for data
    # which this class manages.
    # If the 'file' does not exist, this file is used to data strage.
    #
    # Argument 'items' is an array of items to be managed.
    # Not all the items in the 'file' survive.
    # A and B in the file and B and C in items,
    # then B and C is the items which this class manage.
    # A is discarded from record.
    def self.load_file(filename)
        weights = YAML.load_file(filename)
        self.new(weights)
    end

    def dump(io)
        YAML.dump(@tree.names_weights, io)
    end

    def dump_histgram(io)
        encounters = {}
        names_weights.each do |key, weight|
            #val_log2 = (Math::log(weight)/Math::log(2.0)).to_i
            power = Math::log2(weight).ceil
            encounters[power] ||= 0
            encounters[power] += 1
        end
        max = encounters.values.max
        0.upto(16) do |power|
            num = encounters[power] || 0
            stars = "*" * (HISTGRAM_WIDTH.to_f * num / max).ceil
            io.printf("%6d(%4d)|#{stars}\n", 2**power, num)
        end
    end

    def names_weights
        @tree.names_weights
    end

    def names
        names_weights.keys
    end

    # 乱数を利用して優先度で重み付けして要素を選び、要素を返す。
    # num is only for test. User should not use this argument.
    def pick
        @tree.pick
    end

    #重みを重くする。(優先度が上がる)
    def weigh(item)
        @tree.weigh(item)
    end

    #重みを軽くする。(優先度が下がる)
    def lighten(item)
        @tree.lighten(item)
    end

    # 引数 keys で示したものと、
    # 内部的に管理しているデータが整合しているかチェックし、
    # keys に合わせる。
    # 追加されたデータの重みは、データ内に存在する最大値と
    # 同じになる。
    # This affects destructively.
    def merge(keys)
        new_weights = {}
        new_keys = []
        max = 0
        data = @tree.names_weights
        keys.each do |key|
            new_weights[key] = data[key]

            if data[key] == nil
                #substitute max among exist values afterward
                new_keys << key unless data[key]
                next 
            end

            max = data[key] if max < data[key]
        end

        max = INI_WEIGHT if max < INI_WEIGHT
        new_keys.each do |key|
            new_weights[key] = max
        end

        data = new_weights

        @tree = WeightedPicker::Tree.new(data)
    end

    def total_weight
        @tree.total_weight
    end

    private

    def sanity_data(data)
        data.each do |key, val|
            data[key] = 0 if val < MIN_WEIGHT
            data[key] = MAX_WEIGHT if MAX_WEIGHT < val

            raise InvalidWeightError, "#{val.inspect}, not integer." unless val.is_a? Integer
        end
        data
    end

end
