struct StaticArray
  def to_slice(bytes)
    Slice(T).new(to_unsafe, bytes)
  end
end
