Dot = "@"

# --------------------------- Estado do parser --------------------------- #
class EarleyState
  def initialize(rule, index)
    @rule = rule
    @index = index
  end

  def getRule
    return @rule
  end

  def getIndex
    return @index
  end
end

# --------------------------- Parser de Earley --------------------------- #
class Earley
  def initialize(grammar, expression, reverseGrammar)
    @expression = treatment(expression)
    @s = Array.new(20) {[]}

    @s[0] = [EarleyState.new(Dot + grammar["E"], 0)]
    passer(grammar, reverseGrammar)
  end

  def passer(grammar, reverseGrammar)
    for k in 0..@expression.length
      if @s[k].empty?
        puts "Expressão Inválida"
        return
      end
      for i in @s[k]
        recognize(i)
      end
      
      for state in @s[k]
        recognizeB(state)
        if not finished(state)
          if nextIsNonTerminal(state)
            predictor(state, k, grammar)
          else
            scanner(state, k, @expression)
          end
        else
          completer(state, k, reverseGrammar)
        end
      end
    end

    if @s[@expression.length][-1].getRule != "G" + Dot
      puts "Expressão Inválida"
    else
      puts "Expressão Válida"
    end
  end

  def predictor(state,k,grammar)
    pos = findDot(state.getRule)
    rules = breakRule(grammar[state.getRule[pos + 1]])
    
    for rule in rules
      count = 0

      for r in @s[k]
        if r.getRule == (Dot + rule)
          count += 1
        end
      end

      if count == 0
        @s[k].append(EarleyState.new(Dot + rule, k))
      end
    end

  end

  def scanner(state,k,words)
    if k >= words.length
      return
    end
    pos = findDot(state.getRule)
    if words[k].include? state.getRule[pos + 1] or $numbers.include? words[k]
      rule = state.getRule
      index = state.getIndex
      rule.delete! Dot
      rule.insert(pos + 1, Dot)

      @s[k+1].append(EarleyState.new(rule, index))
    end

  end

  def completer(state, k, reverseGrammar)
    rule = state.getRule
    rg = rule.clone
    rg.delete! Dot

    for cases in @s[state.getIndex]
      if cases.getRule.include? Dot + reverseGrammar[rg]
        rule = cases.getRule
        r = rule.clone
        i = findDot(r)
        r.delete! Dot
        r.insert(i+1, Dot)
        @s[k].append(EarleyState.new(r, cases.getIndex))
      end
    end
  end

  def finished(state)
    if state.getRule[-1] == Dot
      return true
    end
    return false
  end

  def nextIsNonTerminal(state)
    pos = findDot(state.getRule)
    if $terminal.include? state.getRule[pos + 1]
      return false
    end
    return true
  end

  def findDot(rule)
    for i in 0..rule.length - 1
      if rule[i] == Dot
        return i
      end
    end
  end

  def breakRule(rule)
    rules = rule.split("|")
    return rules
  end

  def treatment(expression) 
    e = expression.gsub(/\s+/, "")
    e = e.gsub(/\d+/,"n")
    return e
  end

  def recognize(rule)
    g = rule.clone
    if g.getRule == "X@J"
      addToPrints("Expressão unária reconhecida: -N")
    elsif g.getRule == "#@" or g.getRule == "KJ@"
      addToPrints("Expressão unária reconhecida: número N")
    elsif g.getRule == ")@"
      addToPrints("Expressão unária reconhecida: ( G )")
    end
  end

  def recognizeB(rule)
    g = rule.clone
    if g.getRule == "H-G@"
      addToPrints("Expressão binária reconhecida: N-N")
    elsif g.getRule == "H+G@"
      addToPrints("Expressão binária reconhecida: N+N")
    elsif g.getRule == "I*H@"
      addToPrints("Expressão binária reconhecida: N*N")
    elsif g.getRule == "I/H@"
      addToPrints("Expressão binária reconhecida: N/N")
    elsif g.getRule == "J^I@"
      addToPrints("Expressão binária reconhecida: N^N")
    elsif g.getRule == "XJ@"
      addToPrints("Possível expressão unária reconhecida: -N")
    end
  end

  def addToPrints(phrase)
    if $prints[-1] != phrase
      $prints.append(phrase)
    end
  end

end

# ------------------------------ Gramática ------------------------------ #
$terminal = [
  "+",
  "-",
  "*",
  "/",
  "^",
  "(",
  ")",
  "#"
]

$numbers = [
  "n"
]

grammar = {
  "E" => "G",
  "G" => "H+G|H-G|H|L",
  "H" => "I*H|I/H|I|L",
  "I" => "J^I|J|L",
  "J" => "XJ|K|L",
  "L" => "YGZ",
  "K" => "#",
  "X" => "-",
  "Y" => "(",
  "Z" => ")"  
}

reverseGrammar = {
  "G" => "E",

  "H+G" => "G",
  "H-G" => "G",
  "H" => "G",
  "L" => "G",

  "I*H" => "H",
  "I/H" => "H",
  "I" => "H",
  "L" => "H",

  "J^I" => "I",
  "J" => "I",
  "L" => "I",
 
  "XJ" => "J",
  "K" => "J",
  "L" => "J",

  "YGZ" => "L",
  "#" => "K",
  "-" => "X",
  "(" => "Y",
  ")" => "Z"
}

#Expressões validas
e1 = "(1+4)*2^4"
e2 = "7/(1-3)"
e3 = "9^(1*6/2+4)"
e4 = "2+4^-4/4" #-> detecta dois n+n extra
e10 = "(2+4^--4/4)^3" #-> detecta um n+n extra
e11 = "-------------7"
e12 = "9^(1*-2+3)-3/(6+3)"
e13 = "225-4"

#Expressões invalidas
e5 = "^2+4"
e6 = "9*2+"
e7 = "9++3"
e8 = "()*3"
e9 = "(3+3"

# ----------------------------- Inicializar ----------------------------- #
while true
  system "clear"
  $prints = []

  puts "Digite a expressão que você deseja validar."
  puts "Você também pode digitar um \"e\", seguido de um número de 1 a 13, para testar uma das expressões pré definidas (Exemplo: e7)."
  puts "Sua escolha/Expressão:"
  escolha = gets.chomp
  puts "#############################################################\n\n"
  
  case escolha
    when "e1"
      passer = Earley.new(grammar, e1, reverseGrammar)
      puts "\nExpressão: " + e1
    when "e2"
      passer = Earley.new(grammar, e2, reverseGrammar)
      puts "\nExpressão: " + e2
    when "e3"
      passer = Earley.new(grammar, e3, reverseGrammar)
      puts "\nExpressão: " + e3
    when "e4"
      passer = Earley.new(grammar, e4, reverseGrammar)
      puts "\nExpressão: " + e4
    when "e5"
      passer = Earley.new(grammar, e5, reverseGrammar)
      puts "\nExpressão: " + e5
    when "e6"
      passer = Earley.new(grammar, e6, reverseGrammar)
      puts "\nExpressão: " + e6
    when "e7"
      passer = Earley.new(grammar, e7, reverseGrammar)
      puts "\nExpressão: " + e7
    when "e8"
      passer = Earley.new(grammar, e8, reverseGrammar)
      puts "\nExpressão: " + e8
    when "e9"
      passer = Earley.new(grammar, e9, reverseGrammar)
      puts "\nExpressão: " + e9
    when "e10"
      passer = Earley.new(grammar, e10, reverseGrammar)
      puts "\nExpressão: " + e10
    when "e11"
      passer = Earley.new(grammar, e11, reverseGrammar)
      puts "\nExpressão: " + e11
    when "e12"
      passer = Earley.new(grammar, e12, reverseGrammar)
      puts "\nExpressão: " + e12
    when "e13"
      passer = Earley.new(grammar, e13, reverseGrammar)
      puts "\nExpressão: " + e13
    else
      passer = Earley.new(grammar, escolha, reverseGrammar)
      puts "\nExpressão: " + escolha
  end

  puts "\n"
  puts $prints
  puts "#############################################################\n\n"

  puts "Deseja validar uma nova expressão? (S/N)"
  close = gets.chomp
  if close == "S" or close == "s"
    next
  elsif close == "N" or close == "n"
    break
  else
    puts "\nErro! Encerrando programa..."
    break
  end

end

puts "Obrigada por usar o reconhecedor :D"