#################################################################################
# Refactor ComputerBreaker code
# Add functionality to retake erronous human feedback
# Add functionality to identify erronous human feedback for computerBreaker
# Add functionality to count games won by which roles
# End - Remove unneccessary global variables
# End - Consider putting all repeated code into a super class / module
################################################################################
$trials = []
$feedback = []

module HumanInteraction
    def code_request
        puts "please enter your code."
        print "> "
        check(gets.chomp)
        puts ""
    end

    def sanitize(input)
      input.scan(/\d/).slice(0,4)
    end

    def check(input)
      code = sanitize(input)
      code.size == 4 ? process(code) : error
    end

    def error
      puts "\nInsufficient digits,"
      puts "4 digits required,"
      code_request
    end
end

module Board
    def printed(array)
        array.each {|e| print "#{e} "}
    end

    def display
        puts ""
        $trials.each_with_index do |trial, i|
          printed($feedback[i])
          print "  :  "
          printed($trials[i])
          puts ""
      end
      puts ""
    end

    def vacant(b,w)
        4 - b - w
    end

    def feedback_display(b, w)
        d = []
        b.times {d << 'B'}
        w.times {d << 'W'}
        vacant(b,w).times {d << '-'}
        d
    end
end

module Feedback
    def black
      b = (0..3).select { |i| $secret_code[i] == $trials.last[i] }
      black = b.size
    end

    def white_calc
        int = $secret_code & $trials.last
        found = 0
        int.each do |n|
            c = $secret_code.count(n)
            t = $trials.last.count(n)
            found += [c,t].min
        end
        found
    end

    def white
        white_calc - black
    end

end

##################################################################################################################################
class ComputerMaker
  include Board
  include Feedback
  attr_accessor :guesses, :code

  def initialize
    #@code = Array.new(4) { rand(6).to_s }
  end

  def start
      $secret_code = Array.new(4) { rand(6).to_s }
  end

  def feedback
      $feedback << feedback_display(black.to_i, white.to_i)
      display
  end

  def win
      puts $g.breaker.class == HumanBreaker ? "Computer wins!" : "ComputerMaker wins!"
      puts ""
  end

end

class HumanMaker
    include HumanInteraction
    include Board

    def initialize
        @black = 0
        @white = 0
    end

    def start
        puts "\nPlayer 1, please think of a code."
        puts "Press enter when ready."
        gets.chomp
        #print "\nPlayer 1, "
        #code_request
    end

    def process(secret_code)
        $secret_code = [secret_code]
    end

    def feedback_request(color)
        print "Player 1, how many #{color} pegs for the trial: "
        printed($trials.last);
        print "\n> "
        gets.chomp.to_i
    end

    def black
        @black = feedback_request("black")
    end

    def white
        @white = feedback_request("white")
    end

    def feedback_checked
        black + white <= 4
    end

    def feedback
        if feedback_checked
            $feedback << feedback_display(@black, @white)
            display
        else
            error
        end
    end

    def error
        puts "\nFeedback exceeds 4 spaces"
        puts "Please recheck and try again\n\n"
        feedback
    end

    def win
        puts $g.breaker.class == HumanBreaker ? "Player 1 wins!" : "Your code was unbroken. You win!"
        puts ""
    end
end

class HumanBreaker
    include HumanInteraction

    def start
        play
    end

    def play
        print "Player 2, "
        code_request
    end

    def process(trial)
        $trials << trial
    end

    def win
        puts $g.maker.class == HumanMaker ? "Player 2 wins!" : "You win!"
        puts ""
    end
end

class ComputerBreaker
    include Feedback

    def start
        $trials << Array.new(4) { rand(6).to_s }
    end

    def play
        (0..5555).each do |n|
            proposal = ("%04d" % n).split('')
            next if $trials.include? proposal
            match_all_trials = true

            $trials.each_with_index do |trial, i|
                b = (0..3).select { |j| proposal[j] == trial[j] }
                black = b.size

                int = proposal & trial
                found = 0
                int.each do |n|
                    c = proposal.count(n)
                    t = trial.count(n)
                    found += [c,t].min
                end

                white = found - black

                vacant = 4 - black - white

                proposal_feedback = []
                black.times {proposal_feedback << 'B'}
                white.times {proposal_feedback << 'W'}
                vacant.times {proposal_feedback << '-'}

                if proposal_feedback != $feedback[i]
                    match_all_trials = false
                    break
                end
            end # $trials
            if match_all_trials
                $trials << proposal
                break
            end
        end # (0..5555)
    end #method

    def win
        puts $g.maker.class == HumanMaker ? "Computer wins!" : "ComputerBreaker wins"
        puts ""
    end
end

class PlayerSelect
    attr_reader :maker, :breaker

    def initialize
        @maker = nil
        @breaker = nil
    end

    def role_request(determine)
        puts "\nWho will #{determine} the code?"
        puts "1. Human", "2. Computer"
        print "> "
    end

    def maker
        role_request("make")
        case gets.chomp.downcase
        when /1|human/ then @maker = HumanMaker.new
        when /2|computer/ then @maker = ComputerMaker.new
        else
            error
            maker
        end
    end

    def breaker
        role_request("break")
        case gets.chomp.downcase
        when /[1|human]/ then @breaker = HumanBreaker.new
        when /[2|computer]/ then @breaker = ComputerBreaker.new
        else
            error
            breaker
        end
    end

    def error
        puts "\nInvalid input,"
        puts "Please select '1' or '2'."
    end

end

class Game
    include Board
    attr_reader :maker, :breaker

    def initialize
        p = PlayerSelect.new
        @maker = p.maker
        @breaker = p.breaker
        @plays = 0
        @total_plays = 10
    end

    def play
        (@total_plays * 2 + 1).times { broken? ? broken : player_turn }
        broken? ? broken : unbroken
    end

    def player_turn
        if @plays == 0
            @maker.start
        elsif @plays == 1
            @breaker.start
        elsif @plays % 2 == 0
            @maker.feedback
        elsif @plays % 2 == 1
            @breaker.play
        end
        @plays += 1
    end

    def broken?
      $feedback.any? do |f|
          f.all? { |e| e == "B"}
      end
    end

    def broken
        @breaker.win
        exit(0)
    end

    def unbroken
        @maker.win
    end

    def game_over
      puts "\nGAME OVER"
      print "The code was: [ "
      printed($secret_code)
      puts "]\n\n"
    end

end

$g = Game.new
$g.play
