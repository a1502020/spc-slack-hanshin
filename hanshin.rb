require 'json'
require './rat-evaluator'


class Hanshin

  def initialize(file = 'hanshin')
    @file = file
    @hash = {334 => '334'}
    @rat = RatEvaluator.new
    self.set_cost { |l, r| l.length < r.length || (l.length == r.length && l.count('4') < r.count('4')) }
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


  def valid?(expr)
    return false unless expr.match(/^[34\+\-\*\/\(\)]+$/)
    arr = '334'
    arr_i = 0
    for i in 0..(expr.length) do
      if expr[i] == '3' || expr[i] == '4'
        return false if expr[i] != arr[arr_i]
        arr_i = (arr_i + 1) % 3
      end
    end
    return false if arr_i != 0
    begin
      @rat.eval(expr)
    rescue
      return false
    end
    return true
  end


  def set(expr, with_save = true, force = false)
    return nil unless valid?(expr)
    rat = @rat.eval(expr)
    return nil if rat.denominator != 1
    n = rat.numerator
    return nil if !force && @hash.has_key?(n) && !@cost.call(expr, @hash[n])
    @hash[n] = expr
    self.save if with_save
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

