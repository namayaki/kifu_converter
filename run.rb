require 'csv'

INPUT_DIR = './inputs'
OUTPUT_PATH = './outputs/result.csv'

KIFU_CSA_NUM_MAP = {
  '１' => '1',
  '一' => '1',
  '２' => '2',
  '二' => '2',
  '３' => '3',
  '三' => '3',
  '４' => '4',
  '四' => '4',
  '５' => '5',
  '五' => '5',
  '６' => '6',
  '六' => '6',
  '７' => '7',
  '七' => '7',
  '８' => '8',
  '八' => '8',
  '９' => '9',
  '九' => '9',
}

KIFU_CSA_PIECE_MAP = {
  '歩' => 'FU',
  '歩成' => 'TO',
  'と' => 'TO',
  '香' => 'KY',
  '香成' => 'NY',
  '成香' => 'NY',
  '桂' => 'KE',
  '桂成' => 'NK',
  '成桂' => 'NK',
  '銀' => 'GI',
  '銀成' => 'NG',
  '成銀' => 'GI',
  '金' => 'KI',
  '角' => 'KA',
  '角成' => 'UM',
  '馬' => 'UM',
  '飛' => 'HI',
  '飛成' => 'RY',
  '龍' => 'RY',
  '玉' => 'OU',
}

CSA_USI_PIECE_MAP = {
  'FU' => 'P',
  'KY' => 'L',
  'KE' => 'N',
  'GI' => 'S',
  'KI' => 'G',
  'KA' => 'B',
  'HI' => 'R',
  'OU' => 'K',
  'TO' => '+P',
  'NY' => '+L',
  'NK' => '+N',
  'NG' => '+S',
  'UM' => '+B', 
  'RY' => '+R',
}

class Board
  def initialize
    @turn = 0
    @board = [
      ['l','n','s','g','k','g','s','n','l'],
      ['','r','','','','','','b',''],
      ['p','p','p','p','p','p','p','p','p'],
      ['','','','','','','','',''],
      ['','','','','','','','',''],
      ['','','','','','','','',''],
      ['P','P','P','P','P','P','P','P','P'],
      ['','B','','','','','','R',''],
      ['L','N','S','G','K','G','S','N','L'],
    ]
    @white_hand = {}
    @black_hand = {}
  end

  def to_sfen
    sfen_board = []
    for row in @board do
      line = ''
      count = 0
      for c in row
        if c == ''
          count += 1
          next
        end
        if count > 0
          line += count.to_s
          count = 0
        end
        line += c
      end
      line += count.to_s if count > 0
      sfen_board << line
    end

    sfen = sprintf(
      "%s %s %s%s",
      sfen_board.join('/'),
      @turn%2 == 0 ? 'w' : 'b',
      to_sfen_hand(@white_hand),
      to_sfen_hand(@black_hand),
    )
    return sfen
  end

  def to_sfen_hand(hand)
    sfen = ''
    hand.each do |k, v|
      sfen += v.to_s + k if v > 0
    end
    sfen
  end

  def operate(move)
    from_x = 9 - move[0].to_i
    from_y = move[1].to_i - 1
    to_x = 9 - move[2].to_i
    to_y = move[3].to_i - 1
    piece = CSA_USI_PIECE_MAP[move[4..5]]
    piece = piece.downcase if @turn % 2 == 1
    hand = @turn % 2 == 0 ? @white_hand : @black_hand

    # fromの処理
    if from_x == 9 && from_y == -1
      hand[piece] = hand[piece] - 1
      raise Exception.exception("invalid hand piece") if hand[piece] < 0
    else
      @board[from_y][from_x] = ''
    end

    # toの処理
    e_piece = @board[to_y][to_x]
    if e_piece != ''
      e_piece = e_piece[1] if e_piece.start_with?('+')  
      e_piece = @turn % 2 == 0 ? e_piece.upcase : e_piece.downcase
      hand[e_piece] = 0 unless hand[e_piece]
      hand[e_piece] = hand[e_piece] + 1
    end
    @board[to_y][to_x] = piece
    @turn += 1
  end

  def turn
    @turn
  end
end

def convert_csa(file_path)
  moves = []
  File.open(file_path, encoding: 'Windows-31J') do |file|
    file.each_line do |line|
      line =  line.encode('UTF-8') rescue next
      m = line.match(/.+? (.+?)  \(.+?\).*?/)
      next unless m
      moves << convert_csa_move(m[1])
    end
  end
  return moves
end

def convert_csa_move(move)
  m = move.match(/(.)(.)(.+?)(\((.+?)\)|打)/)
  from = m[4] == '打' ? '00' : m[5]
  move = sprintf('%s%s%s%s', from, KIFU_CSA_NUM_MAP[m[1]], KIFU_CSA_NUM_MAP[m[2]], KIFU_CSA_PIECE_MAP[m[3]])
  raise Exception.exception(sprintf('invalid csa format %s', move)) if move.size != 6
  move
end

results = []
Dir.open(INPUT_DIR) do |dir|
  for file in dir
    next if ['.', '..', '.gitkeep'].include?(file)
    moves = convert_csa(INPUT_DIR + '/' + file)
    board = Board.new
    moves.each do |move|
      board.operate(move)
      sfen = board.to_sfen
      results << [file, board.turn, sfen]
    end
  end
end

CSV.open(OUTPUT_PATH, 'wb') do |file|
  results.each do |r|
    file << r
  end
end