require 'json'
require './rat-evaluator'


class Hanshin

  def initialize(file = 'hanshin')
    @file = file
    @hash = {334 => '334'}
    @rat = RatEvaluator.new
    self.set_cost { |expr| expr.length }
    if File.exists?(@file)
      self.load
    else
      self.save
    end
  end


  attr_reader :file


  def set_cost(&cost)
    @cost = proc(&cost)
  end


  def set(expr)
    rat = @rat.eval(expr)
    return nil if rat.denominator != 1
    n = rat.numerator
    return nil if @hash.has_key?(n) && @cost.call(expr) >= @cost.call(@hash[n])
    @hash[n] = expr
    self.save
    return n
  end

  def get(n)
    @hash.has_key?(n) ? @hash[n] : nil
  end


  def load
    JSON.parse(File.read(@file)).map { |k, v| @hash[k.to_i] = v }
  end

  def save
    File.write @file, @hash.to_json
  end

end

