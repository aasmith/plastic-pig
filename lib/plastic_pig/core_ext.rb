class ::Range
  def crossed_below?(n)
    first > n and last < n
  end

  def crossed_above?(n)
    first < n and last > n
  end
end

class Float
  def places(n=2)
    n = 10 ** n.to_f
    (self * n).truncate / n
  end
end

