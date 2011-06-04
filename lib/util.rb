#object helpers
class Object
  def require_type name, possible_types
    raise "#{name} must be one of #{possible_types.join 'or'}" if not possible_types.include? self.class
  end
end