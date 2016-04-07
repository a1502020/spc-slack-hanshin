class RatEvaluator

  def eval(expr)
    @expr = expr
    @pos = 0
    return eval_expr
  end


  private

  def next_ch
    @pos < @expr.length ? @expr[@pos] : ''
  end

  def eval_expr
    res = eval_term
    while true
      case next_ch
      when '+'
        @pos += 1
        res += eval_term
      when '-'
        @pos += 1
        res -= eval_term
      else
        break
      end
    end
    return res
  end

  def eval_term
    res = eval_fact
    while true
      case next_ch
      when '*'
        @pos += 1
        res *= eval_fact
      when '/'
        @pos += 1
        res /= eval_fact
      else
        break
      end
    end
    return res
  end

  def eval_fact
    res = Rational(0, 1)
    case next_ch
    when '0'..'9'
      while ('0'..'9').include?(next_ch)
        res *= 10
        res += next_ch.to_i
        @pos += 1
      end
    when '('
      @pos += 1
      res = eval_expr
      raise "parse error: expected ')'." if next_ch != ')'
      @pos += 1
    when '-'
      @pos += 1
      res = -1 * eval_expr
    else
      raise "parse error: expected number or '('."
    end
    return res
  end

end

