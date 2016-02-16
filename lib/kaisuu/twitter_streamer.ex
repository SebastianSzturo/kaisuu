defmodule Kaisuu.TwitterStreamer do
  use GenServer
  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(state) do
    send(self, :start_streaming)

    {:ok, state}
  end

  def handle_info(:start_streaming, state) do
    spawn_link fn ->
      # Coordinates for most of Japan
      japan = "129.484177, 30.923179, 145.985641, 45.799878"

      stream = ExTwitter.stream_filter([locations: japan, language: "ja"], :infinity)
      |> Stream.filter(fn(tweet) -> tweet_is_unique(tweet) end)
      |> Stream.map(fn(tweet) -> tweet.text end)
      |> Stream.map(fn(text) -> remove_non_kanji_characters(text) end)
      |> Stream.flat_map(fn(text) -> extract_kanji(text) end)
      |> Stream.map(fn(kanji) -> write_to_redis(kanji) end)
      |> Stream.map(fn(kanji) -> broadcast(kanji) end)
      Enum.to_list(stream)
    end

    {:noreply, state}
  end

  defp tweet_is_unique(tweet) do
    unique = true
    if tweet.favorited,     do: unique = false
    if tweet.retweeted,     do: unique = false
    if tweet.quoted_status, do: unique = false
    unique
  end

  defp remove_non_kanji_characters(text) do
    # https://gist.github.com/SebastianSzturo/686e792c0891904af5e5
    non_jouyou_kanji_regex = ~r/[^一丁七万-下不与且世丘丙両並中串丸丹主丼久乏乗乙九乞乱乳乾亀了予争事二互五井亜亡交享-亭人仁今介仏仕他付仙代-以仮仰仲件任企伎-休会伝伯伴伸伺似但位-佐体何余作佳併使例侍供依価侮侯侵侶便係促俊俗保信修俳俵俸俺倉個倍倒候借倣値倫倹偉偏停健側-偶偽傍傑傘備催傲債傷傾僅働像僕僚僧儀億儒償優元-兆先光克免児党入全八-六共兵具典兼内円冊再冒冗写冠冥冬冶冷凄准凍凝凡処凶凸-出刀刃分-刈刊刑列初判別利到制-刻則削前剖剛剣-剥副剰割創劇力功加劣助努励労効劾勃勅勇勉動勘務勝募勢勤勧勲勾匂包化北匠匹-医匿十千升午半卑-協南単博占印危即-卵卸厄厘厚原厳去参又及-収叔取受叙口-句叫召可-右号司各合吉同-向君吟否含吸吹呂呈-告周呪味呼命和咲咽哀品員哲哺唄唆唇唐唯唱唾商問啓善喉喚喜喝喩-喫営嗅嗣嘆嘱嘲器噴嚇囚四回因団困囲図固国圏園土圧在地坂均坊坑坪垂型垣埋城域執培基埼堀堂堅堆堕堤堪場塀塁塊塑塔塗塚塞塩填塾境墓増墜墨墳墾壁壇壊壌士壮声-売変夏夕外多夜夢大天-夫央失奇-奉奏契奔奥奨奪奮女奴好如-妄妊妖妙妥妨妬妹姉始姓委姫姻姿威娘娠娯婆婚婦婿媒媛嫁嫉嫌嫡嬢子孔字存孝季孤学孫宅宇-安完宗-宝実客-室宮宰害-家容宿寂寄密富寒寛寝察寡寧審寮寸寺対寿封専射将尉-尋導小少尚就尺-局居屈届屋展属層履屯山岐岡岩岬岳岸峠峡峰島崇崎崖崩嵐川州巡巣工-巨差己巻巾市布帆希帝帥師席帯帰帳常帽幅幕幣干-年幸幹幻-幾庁広床序底店府度座庫庭庶-庸廃廉廊延廷建弁弄弊式弐弓-引弟弥-弧弱張強弾当彙形彩彫彰影役彼往征径待律後徐徒従得御復循微徳徴徹心必忌忍志-忙応忠快念怒怖思怠急性怨怪恋恐恒恣恥恨恩恭息恵悔悟悠患悦悩悪悲悼情惑惜惧惨惰想愁愉意愚愛感慄慈態慌慎慕慢慣慨慮慰慶憂憎憤憧憩憬憲憶憾懇懐懲懸成-戒戚戦戯戴戸戻房所扇扉手才打払扱扶批承技抄把抑投抗折抜択披抱抵抹押抽担拉拍拐拒拓拘拙招拝拠拡括拭拳拶拷拾持指挑挙挟挨挫振挿捉捕捗捜捨据捻掃授掌排掘掛採探接控推措掲描提揚換握揮援揺損搬搭携搾摂摘摩摯撃撤撮撲擁操擦擬支改攻放政故敏救敗教敢散敬数整敵敷文斉斎斑斗料斜斤斥斬断新方施旅旋族旗既日-早旬旺昆昇明易昔星映春昧昨昭是昼時晩普景晴晶暁暇暑暖暗暦暫暮暴曇曖曜曲更書曹曽替最月有服朕朗望朝期木未-札朱朴机朽杉材村束条来杯東松板析枕林枚果枝枠枢枯架柄某染柔柱柳柵査柿栃栄栓校株核根格栽桁桃案桑桜桟梅梗梨械棄棋棒棚棟森棺椅植椎検業極楷楼楽概構様槽標模権横樹橋機欄欠次欧欲欺款歌歓止正武歩歯歳歴死殉-残殖殴段殺殻殿毀母毎毒比毛氏民気水氷永氾汁求汎汗汚江池汰決汽沃沈沖沙没沢河沸油治沼沿況泉泊泌法泡-泣泥注泰泳洋洗洞津洪活派流浄浅浜浦浪浮浴海浸消涙涯液涼淑淡淫深混添清渇-渉渋渓減渡渦温測港湖湧湯湾-満源準溝溶溺滅滋滑滝滞滴漁漂漆漏演漠漢漫漬漸潔潜潟潤潮潰澄激濁濃濫濯瀬火灯灰災炉炊炎炭点為烈無焦然焼煎煙照煩煮熊熟熱燃燥爆爪爵父爽片版牙牛牧物牲特犠犬犯状狂狙狩独狭猛猟猫献猶猿獄獣獲玄率玉王玩珍珠班現球理琴瑠璃璧環璽瓦瓶甘甚生産用田-申男町画界畏畑畔留畜畝略番異畳畿疎疑疫疲疾病症痕痘痛痢痩痴瘍療癒癖発登白百的皆皇皮皿盆益盗盛盟監盤目盲直相盾省眉看県真眠眺眼着睡督睦瞬瞭瞳矛矢知短矯石砂研砕砲破硝硫硬碁碑確磁磨礁礎示礼社祈祉祖祝神祥票祭禁禅禍福秀私秋科秒秘租秩称移程税稚種稲稼稽稿穀穂積穏穫穴究空突窃窒窓窟窮窯立竜章童端競竹笑笛符第筆等筋筒答策箇箋算管箱箸節範築篤簡簿籍籠米粉粋粒粗粘粛粧精糖糧糸系糾紀約紅紋納純紙-紛素-索紫累細紳紹紺終組経結絞絡給統絵絶絹継続維綱網綻綿緊総緑緒線締編緩緯練緻縁縄縛縦縫縮績繁繊織繕繭繰缶罪置罰署罵罷羅羊美羞群羨義羽翁翌習翻翼老考者耐耕耗耳聖聞聴職肉肌肖肘肝股肢肥肩肪肯育肺胃胆背胎胞胴胸能脂脅脇脈脊脚脱脳腎腐腕腫腰腸-腺膚膜膝膨膳臆臓臣臨自臭至致臼興舌舎舗舞舟航般舶舷船艇艦良色艶芋芝芯花芳芸芽苗苛若苦英茂茎茨茶草荒荘荷菊菌菓菜華萎落葉著葛葬蒸蓄蓋蔑蔵蔽薄薦薪-薬藍藤藩藻虎虐虚虜虞虫虹蚊蚕蛇蛍蛮蜂蜜融血衆行術街衛衝衡衣表衰衷袋袖被裁裂装裏裕補裸製裾複褐褒襟襲西要覆覇見規視覚覧親観角解触言訂訃計討訓託記訟訪設許訳訴診証詐詔評詞詠詣試詩詮詰-詳誇誉誌認誓誕誘語誠誤説読誰課調談請論諦諧諭諮諸諾謀謁謄謎謙講謝謡謹識譜警議譲護谷豆豊豚象豪貌貝貞負-貢貧-責貯貴買貸費貼貿賀賂-賄資賊賓賛賜賞賠賢賦質賭購贈赤赦走赴起超越趣足距跡路跳践踊踏踪蹴躍身車軌軍軒軟転軸軽較載輝輩輪輸轄辛辞辣辱農辺込迅迎近返迫迭述迷追退送逃逆透逐逓途通逝速造連逮週進逸遂遅遇遊運遍過道-違遜遠遡遣適遭遮遵遷選遺避還那邦邪邸郊郎郡部郭郵郷都酌-酎酒酔酢酪酬酵酷酸醒醜醸采釈里-量金釜針釣鈍鈴鉄鉛鉢鉱銀銃銅銘銭鋭鋳鋼錠錦錬錮錯録鍋鍛鍵鎌鎖鎮鏡鐘鑑長門閉開閑間関閣閥閲闇闘阜阪防阻附降限陛院-陥陪陰陳陵陶陸険陽隅隆隊階随隔隙際障隠隣隷隻雄-雇雌雑離難雨雪雰雲零雷電需震霊霜霧露青静非面革靴韓音韻響頂頃項順須預-頓領頬頭頻頼題-顎顔顕願類顧風飛食飢飯飲飼-飾餅養餌餓館首香馬駄-駆駐駒騎騒験騰驚骨骸髄高髪鬱鬼魂魅魔魚鮮鯨鳥鳴鶏鶴鹿麓麗麦麺麻黄黒黙鼓鼻齢]/u
    Regex.replace(non_jouyou_kanji_regex, text, "")
  end

  defp extract_kanji(text) do
    String.codepoints(text)
  end

  defp write_to_redis(kanji) do
    hex_code_point = kanji |> String.to_char_list |> List.first |> Integer.to_string(16)

    add_kanji_to_index = ~w(SADD kanji_data #{hex_code_point})
    increase_kanji_count = ~w(HINCRBY kanji:#{hex_code_point} count 1)
    increase_total_kanji_count = ~w(INCR kanji_data_count)

    commands = [add_kanji_to_index, increase_kanji_count, increase_total_kanji_count]
    Kaisuu.RedisPool.pipeline(commands)

    kanji
  end

  defp broadcast(kanji) do
    hex = kanji |> String.to_char_list |> List.first |> Integer.to_string(16)

    Kaisuu.Endpoint.broadcast! "kanji:all", "new_kanji", %{ kanji: kanji, hex: hex }
    kanji
  end
end
