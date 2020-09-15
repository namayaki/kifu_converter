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
      ['','N','','','','','','R',''],
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
      sfen += k + v.to_s if v > 0
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
    if from_x == 9 && from_y == 9
      hand[piece] = hand[piece] - 1
    else
      @board[from_y][from_x] = ''
    end

    # toの処理
    e_piece = @board[to_y][to_x]
    if e_piece != ''
      e_piece = e_pieace[1] if e_piece.start_with?('+')  
      e_piece = @turn % 2 == 0 ? e_piece.upcase : e_piece_downcase
      hand[e_piece] = 0 unless hand[e_piece]
      hand[e_piece] = hand[e_piece] + 1
    end
    @board[to_y][to_x] = piece
    @turn += 1
  end
end