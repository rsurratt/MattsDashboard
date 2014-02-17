class StatusValue

  attr_accessor :label, :sval, :ival, :goal, :percent_of_goal, :is_money

  def initialize(_label, _sval, _goal)
    self.label = _label
    self.sval = _sval
    self.is_money = _sval.include?("$")
    self.ival = _sval.delete("$., ").to_i
    self.goal = _goal

    if is_money
      _goal = goal * 100  # money ivals are in cents, goal in dollar
    end
    if _goal > 0
      self.percent_of_goal = (ival.to_f / _goal * 100).to_i
    end
  end

  def self.sum(values)
    if values.nil? || values.empty?
      return nil
    end

    sum_ival = 0
    sum_goal = 0
    label = ''
    is_money = false

    values.each { |value|
      if !value.nil?
        label = value.label
        sum_ival = sum_ival + value.ival
        sum_goal = sum_goal + value.goal
        is_money = is_money || value.is_money
      end
    }

    if is_money
      sval = format_dollars(sum_ival)
    else
      sval = sum_ival.to_s
    end

    StatusValue.new(label, sval, sum_goal)
  end

  private
    def self.format_dollars(n)
      s = '%.2f' % (n.to_f / 100.0)
      '$' + s.gsub(/(\d)(?=\d{3}+(?:\.|$))(\d{3}\..*)?/,'\1,\2')
    end
end
