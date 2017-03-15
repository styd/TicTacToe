###############################################
# @author Adrian Setyadi <a_setyadi@zoho.com> #
# @game Tic Tac Toe                           #
###############################################

require "tic_tac_toe/version"

module TicTacToe
  COLOR = :on # Use this if your terminal supports text color
  # COLOR = :off # Use this if your terminal output looks gibberish if COLOR == :on

  class Player
    COLOR_SET = [*(31..36)].cycle

    @@num_of_registered_players = 0
    @@color = COLOR_SET.each

    attr_reader :name, :symbol, :color

    def initialize params = {}
      @@num_of_registered_players += 1
      @color = @@color.next
      @name = params[:name] || "Player " + @@num_of_registered_players.to_s
      symbol = params[:symbol]
      @symbol = COLOR == :off ? symbol : "\e[#{color}m#{symbol}\e[0m"
    end

    def wins
      puts "#{name} wins!"
    end
  end

  class Game
    NotPlayable = Class.new(StandardError)

    attr_accessor :current_player, :current_mark_pos,
                  :players, :play_table, :game_over,
                  :unique_rows, :unique_columns, :unique_diags
    attr_reader :names, :symbols, :size

    def initialize size, symbols, player_names
      @symbols = eval(symbols || "") || ['x', 'o']
      @names = eval(player_names || "") || []
      @size = (size || 3).to_i

      raise NotPlayable,
        "Game is not playable. See examples of possible arguments in source code!"\
        unless playable?
      play
    end

    class << self
      # Force to use `play` instead of `new`
      alias_method :play, :new
      private :new
    end

    def init_players
      self.players = []
      symbols.compact.uniq.size.times do
        name = self.names.shift
        symbol = self.symbols.shift
        self.players << Player.new({name: name, symbol: symbol})
      end
    end

    def playable?
      size > 2 && size <= 50 &&
        symbols.compact.uniq.size > 1 &&
        names.compact.uniq.size <= symbols.compact.uniq.size &&
        symbols.compact.uniq.all? do |m|
          m.is_a?(String) &&        # each should be string
            m.chars.count == 1 &&   # each should contain 1 character
            m.bytes.count == 1      # each should occupy 1 byte
        end
    end

    def wrong_input? input
      message = ""
      if m = input.match(/^(\d+),\s*(\d+)$/)
        if m.to_a.all?{|el| el.to_i.between?(1,size) }
          return false
        else
          message = "Input number should be between 1 and #{size}."
        end
      else
        message = "Make sure input is in the following format: <number>,<number>"
      end
      return message
    end

    def no_longer_winnable?
      (unique_rows + unique_columns + unique_diags).empty?
    end

    # This method will run faster every `play` loop due to the decreasing number
    # of `unique_<lines>` members
    def solved?
      mark_row, mark_col = *current_mark_pos
      symbol = current_player.symbol

      # Check if solved horizontally
      if unique_rows.any? and unique_rows.include? mark_row
        row = play_table[mark_row]
        return true if row.all?{|m| m == symbol }

        # Remove row from unique list if no longer unique
        unique_rows.delete(mark_row) if row.compact.uniq.size > 1
      end

      # Check if solved vertically
      if unique_columns.any? and unique_columns.include? mark_col
        column = []
        size.times do |i|
          column << play_table[i][mark_col]
        end
        return true if column.all?{|m| m == symbol }

        # Remove column unique list if no longer unique
        unique_columns.delete(mark_col) if column.compact.uniq.size > 1
      end

      # Check if solved diagonally
      if (mark_row == mark_col || mark_row == size - mark_col - 1) &&
            unique_diags.any?
        # Initialize diagonals with negative and positive gradients
        neg_diag = []
        pos_diag = []

        size.times do |i|
          neg_diag << play_table[i][i]
          pos_diag << play_table[size-i-1][i]
        end
        return true if neg_diag.all?{|m| m == symbol } || pos_diag.all?{|m| m == symbol }

        # Remove diagonal if no longer unique
        unique_diags.delete(0) if neg_diag.compact.uniq.size > 1
        unique_diags.delete(1) if pos_diag.compact.uniq.size > 1
      end

      # Not yet solved
      return false
    end

    def play
      init_players
      player = self.players.cycle.each

      self.play_table = Array.new(@size){ Array.new(@size) }
      self.unique_rows = [*(0...size)]
      self.unique_columns = [*(0...size)]
      self.unique_diags = [0, 1]

      self.game_over = false
      prepare_screen
      until game_over do
        self.current_player = player.next

        pos_marked = false
        until pos_marked do
          refresh_screen
          show_play_table
          show_note
          prompt
          # Get input
          begin
            input = gets
            if input.nil? # Ctrl + D pressed
              raise Interrupt
            else
              typed_text = input.chomp.strip
            end
          rescue SystemExit, Interrupt # Ctrl + C pressed or program/ruby failure
            forced_to_quit
          end

          wrong_input = wrong_input? typed_text
          if wrong_input
            flash wrong_input
            next
          end

          # The row and column is 1 based
          self.current_mark_pos = typed_text.split(/,\s*/).map{|c| c.to_i-1}

          mark_row, mark_col = *self.current_mark_pos
          symbol = self.current_player.symbol

          unless play_table[mark_row][mark_col]
            play_table[mark_row][mark_col] = symbol
            pos_marked = true
            run_some_checks
          else
            flash "Already marked. Choose another position!"
          end
        end
      end
    end

    def run_some_checks
      end_game if solved?
      end_game :draw if no_longer_winnable?
    end

    def end_game symbol = nil
      self.game_over = true
      refresh_screen
      show_play_table
      puts
      print "Game Over. "
      if symbol == :draw
        puts "It's a draw."
      else
        current_player.wins
      end
    end

    def term_width
      @term_width ||= `tput cols`.to_i
    end

    #
    # Screen related methods
    #
    def show_note
      puts "Type: <#{italicize("row")}>,<#{italicize("column")}>"
      puts
    end

    def prompt
      print "\r #{colorize(current_player.name)}: "
    end

    def show_play_table
      size_width = size.to_s.length
      col_label = "COLUMN".center(3*size)
      row_label = "ROW".center(size)
      print " "*(size_width + 4)
      print "#{italicize(col_label)}" + "\n"
      print " "*(size_width + 4)
      1.upto(size) do |cnum|
        print "#{boldize(cnum.to_s.center(3))}"
      end
      print "\n"
      play_table.each.with_index(1) do |row, rnum|
        print " #{italicize(row_label[rnum-1])}"
        print " #{boldize(rnum.to_s.rjust(size_width))} "
        row.each do |el|
          if COLOR == :off
            print "[#{el || " "}]"
          else
            print el ? "[#{el || " "}]\e[0m" : "[#{el || " "}]"
          end
        end
        puts
      end
    end

    def prepare_screen
      (size+5).times{ puts }
    end

    def refresh_screen
      print "\r\e[#{size+5}A"
      (size+5).times do
        print " " * term_width + "\n"
      end
      print "\r\e[#{size+5}A"
    end

    def forced_to_quit
      puts
      refresh_screen
      print "Game Over. "
      puts italicize("Forced to quit.")
      exit
    end

    def colorize text
      if COLOR == :off
        return text
      else
        color = current_player.color
        return "\e[#{color}m#{text}\e[0m"
      end
    end

    def italicize text
      if COLOR == :off
        return text
      else
        open = "\e[3m"
        close = "\e[0m"
        return "#{open}#{text}#{close}"
      end
    end

    def boldize text
      if COLOR == :off
        return text
      else
        open = "\e[1m"
        close = "\e[0m"
        return "#{open}#{text}#{close}"
      end
    end

    def flash text
      print "\r\e[A" + " " * term_width
      prompt
      if COLOR == :off
        print text
      else
        print "\e[33m#{text}\e[0m"
      end
      sleep 2
      puts
    end
  end
end
